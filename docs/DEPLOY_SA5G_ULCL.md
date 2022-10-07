<table style="border-collapse: collapse; border: none;">
  <tr style="border-collapse: collapse; border: none;">
    <td style="border-collapse: collapse; border: none;">
      <a href="http://www.openairinterface.org/">
         <img src="./images/oai_final_logo.png" alt="" border=3 height=50 width=150>
         </img>
      </a>
    </td>
    <td style="border-collapse: collapse; border: none; vertical-align: center;">
      <b><font size = "5">OpenAirInterface 5G Core UL CL Network Deployment and Testing with gnbsim</font></b>
    </td>
  </tr>
</table>

![SA UL CL Scenario](./images/5gcn_ulcl.png)

**Reading time: ~ 20 minutes**

**Tutorial replication time: ~ 1h**

**Compute resource recommendation: ~ 6GB RAM, 8CPU**

Each instance of VPP-UPF runs on a different CPU (logical) core (0-1 ULCL1, 2-3 A-UPF1, 4-5 A-UPF2) to distribute the 
workload. You need at least 6 logical CPU cores for this tutorial. 


Note: In case readers are interested in deploying debuggers/developers core network environment with more logs please follow [this tutorial](./DEBUG_5G_CORE.md)

**TABLE OF CONTENTS**

1.  Pre-requisites
2.  [Building Container Images](./BUILD_IMAGES.md) or [Retrieving Container Images](./RETRIEVE_OFFICIAL_IMAGES.md)
3.  [Retrieve Experimental Images](#3-retrieve-experimental-images) 
4.  [Deploying OAI 5G Core Network](#4-deploying-oai-5g-core-network)
5.  [Simulate with gnbsim](#5-simulate-with-gnbsim)
6.  [Traffic Test for UL CL Scenario](#6-traffic-test-for-ul-cl-scenario)
7.  [Traffic Test for Edge-Only Scenario](#7-traffic-test-for-edge-only-scenario)
8.  [Traffic Test for Internet-Only Scenario](#8-traffic-test-for-internet-only-scenario)
9.  [Trace Analysis](#9-trace-analysis)
10.  [Undeploy Network Functions](#10-undeploy-network-functions)
11.  [Conclusion](#11-conclusion)

For this demo, all the images which use the `v1.4.0` have been retrieved from the official `docker-hub` (see also
[Retrieving images](./RETRIEVE_OFFICIAL_IMAGES.md)).
The other images (NRF, SMF, PCF and UPF-VPP) have been built according to the [Building Images](./BUILD_IMAGES.md) tutorial.

| CNF Name | Branch Name              | Tag used at time of writing | Ubuntu 18.04 | RHEL8 |
|----------|:-------------------------|-----------------------------|--------------|-------|
| NSSF     | `master`                 | `v1.4.0`                    | X            | -     |
| AMF      | `master`                 | `v1.4.0`                    | X            | -     |
| AUSF     | `master`                 | `v1.4.0`                    | X            | -     |
| NRF      | -                        | `2fc1fc12` (commit)         | X            | -     |
| SMF      | `feature_edge_computing` | -                           | X            | -     |
| UDR      | `master`                 | `v1.4.0`                    | X            | -     |
| UDM      | `master`                 | `v1.4.0`                    | X            | -     |
| PCF      | `develop`                | -                           | X            | -     |
| UPF-VPP  | `edge_computing`         | -                           | X            | -     |

<br/>

This tutorial shows how to configure the UL CL feature at SMF and UPF, based on policies from the PCF.

This requires enabling experimental features on SMF, NRF and UPF-VPP. Also, the PCF is required, which is not released 
yet. Therefore, the images for these NFs have to be built manually (see pre-requisites).

To simplify the deployment, these images have been pushed to the unofficial `docker-hub` repository `stespe`. 

We will show and validate:
* UL CL scenario for a subscriber (gnbsim) with UL traffic classification
* A-UPF scenario to the Internet for another gnbsim subscriber 
* A-UPF scenario to the Edge for another gnbsim subscriber

## 1. Pre-requisites

Create a folder where you can store all the result files of the tutorial and later compare them with our provided result files, we recommend creating exactly the same folder to not break the flow of commands afterwards.

<!---
For CI purposes please ignore this line
``` shell
docker-compose-host $: rm -rf /tmp/oai/ulcl-scenario
```
-->

``` shell
docker-compose-host $: mkdir -p /tmp/oai/ulcl-scenario
docker-compose-host $: chmod 777 /tmp/oai/ulcl-scenario
```

## 3. Retrieve Experimental Images

The images have to be retrieved and then tagged with the `edge-computing` tag for the `docker-compose` file.
If you want to build the images by yourself, you need to check out the branches/commits from the table above.

``` shell
docker-compose-host $: docker pull stespe/oai-nrf:edge_computing
docker-compose-host $: docker tag stespe/oai-nrf:edge_computing oai-nrf:edge_computing
docker-compose-host $: docker pull stespe/oai-smf:edge_computing
docker-compose-host $: docker tag stespe/oai-smf:edge_computing oai-smf:edge_computing
docker-compose-host $: docker pull stespe/oai-pcf:develop
docker-compose-host $: docker tag stespe/oai-pcf:develop oai-pcf:develop
docker-compose-host $: docker pull stespe/oai-upf-vpp:edge_computing
docker-compose-host $: docker tag stespe/oai-upf-vpp:edge_computing oai-upf-vpp:edge_computing
```

## 4. Deploying OAI 5g Core Network

We deploy an adapted version of `basic-vpp` of the 5G core with the PCF as additional NF and 3 UPFs instead of 1.

We use `docker-compose` to deploy the core network. Please refer to the file `docker-compose-basic-vpp-pcf-ulcl.yaml`
for details.

### Docker Networks
In total, 6 different docker networks are used:
* public_net (demo-oai) for control plane 
* public_net_access (cn5g-access) for the N3 interface
* public_net_core_11 (cn5g-core-11) for the N9 interface between ULCL and A-UPF1
* public_net_core_12 (cn5g-core-12) for the N6 interface between A-UPF1 and EXT-DN-Internet
* public_net_core_21 (cn5g-core-21) for the N9 interface between ULCL and A-UPF2
* public_net_core_22 (cn5g-core-22) for the N6 interface between A-UPF2 and EXT-DN-Edge

### Deployment and Tracing

The first interface (demo-oai) is used for the control plane, including the N4 interface to all UPFs. The others are used for the user plane.

Therefore, we do not need to filter out the UP when tracing on the `demo-oai` interface.
We run the `mysql` service first, so that we can start the trace before anything is sent over the CP. 
You can choose to skip this step and deploy all the NFs at once.

``` shell
docker-compose-host $: docker-compose -f docker-compose-basic-vpp-pcf-ulcl.yaml up -d mysql 
Creating network "demo-oai-public-net" with driver "bridge"
Creating network "oai-public-access" with the default driver
Creating network "oai-public-core11" with the default driver
Creating network "oai-public-core21" with the default driver
Creating network "oai-public-core12" with the default driver
Creating network "oai-public-core22" with the default driver
Creating mysql ... done
```


We capture the packets on the docker networks and filter out the ARP. 
``` shell
docker-compose-host $: sleep 1
docker-compose-host $: nohup sudo tshark -i demo-oai -f "not arp" -w /tmp/oai/ulcl-scenario/control_plane.pcap > /dev/null 2>&1 &
docker-compose-host $: sleep 5
```
Then, we start all the NFs.

``` shell
docker-compose-host $: docker-compose -f docker-compose-basic-vpp-pcf-ulcl.yaml up -d
mysql is up-to-date
Creating oai-nrf             ... done
Creating oai-udr             ... done
Creating vpp-upf-aupf2       ... done
Creating vpp-upf-ulcl        ... done
Creating vpp-upf-aupf1       ... done
Creating oai-pcf             ... done
Creating oai-udm             ... done
Creating oai-ext-dn-internet ... done
Creating oai-ext-dn-edge     ... done
Creating oai-ausf            ... done
Creating oai-amf             ... done
Creating oai-smf             ... done
```

``` shell
docker-compose-host $: sleep 30
```

### Checking the Status of the NFs
Using `docker ps` you can verify that no NF exited, e.g. because of a faulty configuration:
``` shell
docker-compose-host $: docker ps
CONTAINER ID   IMAGE                        COMMAND                  CREATED          STATUS                    PORTS                          NAMES
a44783c3b34d   oai-smf:edge_computing       "/bin/bash /openair-…"   14 seconds ago   Up 13 seconds             80/tcp, 9090/tcp, 8805/udp     oai-smf
5106a18426af   oai-amf:v1.4.0               "/bin/bash /openair-…"   15 seconds ago   Up 14 seconds             80/tcp, 9090/tcp, 38412/sctp   oai-amf
a17d96eea1fa   trf-gen-cn5g:latest          "/bin/bash -c 'iptab…"   16 seconds ago   Up 15 seconds (healthy)                                  oai-ext-dn-internet
90a6bd19afbb   trf-gen-cn5g:latest          "/bin/bash -c 'iptab…"   16 seconds ago   Up 15 seconds (healthy)                                  oai-ext-dn-edge
a2469b673615   oai-ausf:v1.4.0              "/bin/bash /openair-…"   16 seconds ago   Up 15 seconds             80/tcp                         oai-ausf
86e54a9aa0c5   oai-udm:v1.4.0               "/bin/bash /openair-…"   17 seconds ago   Up 16 seconds             80/tcp                         oai-udm
ed85ef6814d3   oai-udr:v1.4.0               "/bin/bash /openair-…"   17 seconds ago   Up 17 seconds             80/tcp                         oai-udr
d102f082d7c0   oai-upf-vpp:edge_computing   "/openair-upf/bin/en…"   17 seconds ago   Up 16 seconds (healthy)   2152/udp, 8085/udp             vpp-upf-ulcl
07853e6f8fff   oai-upf-vpp:edge_computing   "/openair-upf/bin/en…"   17 seconds ago   Up 15 seconds (healthy)   2152/udp, 8085/udp             vpp-upf-aupf1
dc8c022f0dd1   oai-upf-vpp:edge_computing   "/openair-upf/bin/en…"   17 seconds ago   Up 16 seconds (healthy)   2152/udp, 8085/udp             vpp-upf-aupf2
7ca41a7e0a0f   oai-pcf:develop              "/bin/bash /openair-…"   17 seconds ago   Up 17 seconds (healthy)   80/tcp, 8080/tcp               oai-pcf
c62491c2dba2   mysql:5.7                    "docker-entrypoint.s…"   18 seconds ago   Up 17 seconds (healthy)   3306/tcp, 33060/tcp            mysql
5c0fdb4c218c   oai-nrf:edge_computing       "/bin/bash /openair-…"   18 seconds ago   Up 17 seconds             80/tcp, 9090/tcp               oai-nrf
```

You should also check the docker logs of SMF and verify that the UPF graph has been built successfully:

``` shell
[2022-10-05T23:38:34.123143] [smf] [smf_app] [debug] Successfully added UPF node: aupf2.node.5gcn.mnc95.mcc208.3gppnetwork.org, (788577021)
[2022-10-05T23:38:34.123164] [smf] [smf_app] [debug] UPF graph 
[2022-10-05T23:38:34.123174] [smf] [smf_app] [debug] 	aupf2.node.5gcn.mnc95.mcc208.3gppnetwork.org --> 
[2022-10-05T23:38:34.123185] [smf] [smf_app] [debug] NF instance info
[2022-10-05T23:38:34.123187] [smf] [smf_app] [debug] 	Instance ID: 0d4d1669-64ff-47e2-bcb0-fa2214debc78
--
[2022-10-05T23:38:36.133429] [smf] [smf_app] [debug] Successfully added UPF node: ulcl.node.5gcn.mnc95.mcc208.3gppnetwork.org, (4216839997)
[2022-10-05T23:38:36.133472] [smf] [smf_app] [debug] Successfully added UPF graph edge between ulcl.node.5gcn.mnc95.mcc208.3gppnetwork.org and aupf2.node.5gcn.mnc95.mcc208.3gppnetwork.org
[2022-10-05T23:38:36.133503] [smf] [smf_app] [debug] UPF graph 
[2022-10-05T23:38:36.133521] [smf] [smf_app] [debug] 	ulcl.node.5gcn.mnc95.mcc208.3gppnetwork.org --> /aupf2.node.5gcn.mnc95.mcc208.3gppnetwork.org: aupf2.node.5gcn.mnc95.mcc208.3gppnetwork.org, 
[2022-10-05T23:38:36.133531] [smf] [smf_app] [debug] 	aupf2.node.5gcn.mnc95.mcc208.3gppnetwork.org --> /ulcl.node.5gcn.mnc95.mcc208.3gppnetwork.org: ulcl.node.5gcn.mnc95.mcc208.3gppnetwork.org, 
[2022-10-05T23:38:36.133541] [smf] [smf_app] [debug] NF instance info
--
[2022-10-05T23:38:38.143114] [smf] [smf_app] [debug] Successfully added UPF node: aupf1.node.5gcn.mnc95.mcc208.3gppnetwork.org, (2944765908)
[2022-10-05T23:38:38.143142] [smf] [smf_app] [debug] Successfully added UPF graph edge between aupf1.node.5gcn.mnc95.mcc208.3gppnetwork.org and ulcl.node.5gcn.mnc95.mcc208.3gppnetwork.org
[2022-10-05T23:38:38.143164] [smf] [smf_app] [debug] UPF graph 
[2022-10-05T23:38:38.143175] [smf] [smf_app] [debug] 	aupf1.node.5gcn.mnc95.mcc208.3gppnetwork.org --> /ulcl.node.5gcn.mnc95.mcc208.3gppnetwork.org: ulcl.node.5gcn.mnc95.mcc208.3gppnetwork.org, 
[2022-10-05T23:38:38.143185] [smf] [smf_app] [debug] 	aupf2.node.5gcn.mnc95.mcc208.3gppnetwork.org --> /ulcl.node.5gcn.mnc95.mcc208.3gppnetwork.org: ulcl.node.5gcn.mnc95.mcc208.3gppnetwork.org, 
[2022-10-05T23:38:38.143195] [smf] [smf_app] [debug] 	ulcl.node.5gcn.mnc95.mcc208.3gppnetwork.org --> /aupf2.node.5gcn.mnc95.mcc208.3gppnetwork.org: aupf2.node.5gcn.mnc95.mcc208.3gppnetwork.org, /aupf1.node.5gcn.mnc95.mcc208.3gppnetwork.org: aupf1.node.5gcn.mnc95.mcc208.3gppnetwork.org, 
```

We see that first AUPF2 is added, followed by ULCL and AUPF1. The order of this may differ. 
It is important that all 3 UPFs are added successfully and that there are the correct edges.
When the graph is fully built, it should look like this:
* ulcl -> /aupf1:aupf1, /aupf2:aupf2 (again, the order does not matter)
* aupf1 -> /ulcl:ulcl
* aupf2 -> /ulcl:ulcl


## 5. Simulate with gnbsim

When the CN is deployed successfully, we can simulate a gNB and UE using `gnbsim`. 
Please see the [gnbsim tutorial](./DEPLOY_SA5G_WITH_GNBSIM.md) on how to retrieve or build the image.

``` shell
docker-compose-host $: docker-compose -f docker-compose-gnbsim-vpp.yaml up -d 
Creating gnbsim-vpp ...
Creating gnbsim-vpp ... done
docker-compose-host $: sleep 30 
```

We can verify that the gNB received an IP address and that the PDU session establishment was successful. 
``` shell
docker-compose-host $: docker logs gnbsim-vpp 2>&1 | grep "UE address:"
[gnbsim]2022/10/06 10:15:45.906862 example.go:332: UE address: 12.1.1.2
```

Please note, that the UL CL is transparent for the UE and this only shows that there is a PDU session, not that
the traffic is routed correctly. Currently, the SMF tries to create a session on any UPF if the selection based on PCC rules 
fails. 

## 6. Traffic Test for UL CL Scenario

*Note: As tshark is running in the background for CI reasons, we will stop the control plane traces here. If you follow this
tutorial manually, you can open tshark on another terminal and terminate them whenever it suits you.*  


Before we start the traffic tests, we start the user plane trace without any filter:
``` shell
docker-compose-host $: nohup sudo tshark -i cn5g-access -i cn5g-core-11 -i cn5g-core-12 -i cn5g-core-21 -i cn5g-core-22 -w /tmp/oai/ulcl-scenario/user_plane_ulcl.pcap > /dev/null 2>&1 &
```

This capture contains all the UP network interfaces.


Then, we generate ICMP traffic to `8.8.8.8` and `1.1.1.1`:

``` shell
docker-compose-host $: docker exec -it gnbsim-vpp ping -I 12.1.1.2 -c4 8.8.8.8
PING 8.8.8.8 (8.8.8.8) from 12.1.1.2 : 56(84) bytes of data.
64 bytes from 8.8.8.8: icmp_seq=1 ttl=114 time=29.3 ms
64 bytes from 8.8.8.8: icmp_seq=2 ttl=114 time=18.8 ms
64 bytes from 8.8.8.8: icmp_seq=3 ttl=114 time=25.4 ms
64 bytes from 8.8.8.8: icmp_seq=4 ttl=114 time=15.2 ms

--- 8.8.8.8 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3003ms
rtt min/avg/max/mdev = 15.200/22.169/29.265/5.484 ms
```

``` shell
docker-compose-host $: docker exec -it gnbsim-vpp ping -I 12.1.1.2 -c4 1.1.1.1
PING 1.1.1.1 (1.1.1.1) from 12.1.1.2 : 56(84) bytes of data.
64 bytes from 1.1.1.1: icmp_seq=1 ttl=55 time=15.7 ms
64 bytes from 1.1.1.1: icmp_seq=2 ttl=55 time=19.8 ms
64 bytes from 1.1.1.1: icmp_seq=3 ttl=55 time=9.77 ms
64 bytes from 1.1.1.1: icmp_seq=4 ttl=55 time=12.3 ms

--- 1.1.1.1 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3005ms
rtt min/avg/max/mdev = 9.766/14.397/19.823/3.785 ms
```

We will see in the [analysis](#9-trace-analysis) that the IP packets to `1.1.1.1` are routed over A-UPF1 and the EXT-DN-Internet and the
packets to `8.8.8.8` are routed over A-UPF2 and the EXT-DN-Edge

To better analyse the traces for the following scenarios, we stop the trace:
``` shell
docker-compose-host $: sudo pkill tshark 
```


## 7. Traffic Test for Edge-Only Scenario
As you can see in the PCC rules (`policies/pcc_rules/pcc_rules.yaml`), there are two edge rules: `edge-rule-restricted` and
`edge-rule-all`. Both use the same traffic rule, but the flow description is configured differently. It means that the
`edge-rule-restricted` allows only traffic to 8.8.8.8, whereas the other rule allows any traffic to the edge.

Which UE uses which PCC rules is configured in the policy decisions file (`policies/policy_decisions/policy_decision.yaml`).
You can see that the UE with the IMSI `208950000000032` is configured to use the `edge-rule-all`. 

To start the edge-only UE, use docker-compose:
``` shell
docker-compose-host $: docker-compose -f docker-compose-gnbsim-vpp-additional.yaml up -d gnbsim-vpp2
TODO
docker-compose-host $: sleep 30 
```

Again, we can verify if the PDU session establishment was successful.
``` shell
docker-compose-host $: docker logs gnbsim-vpp2 2>&1 | grep "UE address:"
[gnbsim]2022/10/06 10:15:45.906862 example.go:332: UE address: 12.1.1.3
```

We start a trace for this scenario:
``` shell
docker-compose-host $: nohup sudo tshark -i cn5g-access -i cn5g-core-11 -i cn5g-core-12 -i cn5g-core-21 -i cn5g-core-22 -w /tmp/oai/ulcl-scenario/user_plane_edge_only.pcap > /dev/null 2>&1 &
```


Then, as before, we ping `8.8.8.8` and `1.1.1.1`. 

``` shell
docker-compose-host $: docker exec -it gnbsim-vpp2 ping -I 12.1.1.3 -c4 8.8.8.8
PING 8.8.8.8 (8.8.8.8) from 12.1.1.3 : 56(84) bytes of data.
64 bytes from 8.8.8.8: icmp_seq=1 ttl=114 time=29.3 ms
64 bytes from 8.8.8.8: icmp_seq=2 ttl=114 time=18.8 ms
64 bytes from 8.8.8.8: icmp_seq=3 ttl=114 time=25.4 ms
64 bytes from 8.8.8.8: icmp_seq=4 ttl=114 time=15.2 ms

--- 8.8.8.8 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3003ms
rtt min/avg/max/mdev = 15.200/22.169/29.265/5.484 ms
```

``` shell
docker-compose-host $: docker exec -it gnbsim-vpp2 ping -I 12.1.1.3 -c4 1.1.1.1
PING 1.1.1.1 (1.1.1.1) from 12.1.1.3 : 56(84) bytes of data.
64 bytes from 1.1.1.1: icmp_seq=1 ttl=55 time=15.7 ms
64 bytes from 1.1.1.1: icmp_seq=2 ttl=55 time=19.8 ms
64 bytes from 1.1.1.1: icmp_seq=3 ttl=55 time=9.77 ms
64 bytes from 1.1.1.1: icmp_seq=4 ttl=55 time=12.3 ms

--- 1.1.1.1 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3005ms
rtt min/avg/max/mdev = 9.766/14.397/19.823/3.785 ms
```

In the [analysis](todo) we see that all this traffic is routed over A-UPF2 and the EXT-DN-Edge.

Again, we stop this trace:
``` shell
docker-compose-host $: sudo pkill tshark
```

## 8. Traffic Test for Internet-Only Scenario
The policies for the IMSI `208950000000033` configure that this subscriber should use the Internet-only scenario.
We start it again using docker-compose:
``` shell
docker-compose-host $: docker-compose -f docker-compose-gnbsim-vpp-additional.yaml up -d gnbsim-vpp3
docker-compose-host $: sleep 30 
```

We verify that the PDU session establishment is successful and that the UP is routed.

``` shell
docker-compose-host $: docker logs gnbsim-vpp3 2>&1 | grep "UE address:"
[gnbsim]2022/10/06 09:50:33.332271 example.go:332: UE address: 12.1.1.4
```

We start a trace for this scenario:
``` shell
docker-compose-host $: nohup sudo tshark -i cn5g-access -i cn5g-core-11 -i cn5g-core-12 -i cn5g-core-21 -i cn5g-core-22 -w /tmp/oai/ulcl-scenario/user_plane_internet_only.pcap > /dev/null 2>&1 &
```

``` shell
docker-compose-host $: docker exec -it gnbsim-vpp3 ping -I 12.1.1.4 -c4 8.8.8.8
PING 8.8.8.8 (8.8.8.8) from 12.1.1.4 : 56(84) bytes of data.
64 bytes from 8.8.8.8: icmp_seq=1 ttl=114 time=29.3 ms
64 bytes from 8.8.8.8: icmp_seq=2 ttl=114 time=18.8 ms
64 bytes from 8.8.8.8: icmp_seq=3 ttl=114 time=25.4 ms
64 bytes from 8.8.8.8: icmp_seq=4 ttl=114 time=15.2 ms

--- 8.8.8.8 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3003ms
rtt min/avg/max/mdev = 15.200/22.169/29.265/5.484 ms
```

``` shell
docker-compose-host $: docker exec -it gnbsim-vpp3 ping -I 12.1.1.4 -c4 1.1.1.1
PING 1.1.1.1 (1.1.1.1) from 12.1.1.4 : 56(84) bytes of data.
64 bytes from 1.1.1.1: icmp_seq=1 ttl=55 time=15.7 ms
64 bytes from 1.1.1.1: icmp_seq=2 ttl=55 time=19.8 ms
64 bytes from 1.1.1.1: icmp_seq=3 ttl=55 time=9.77 ms
64 bytes from 1.1.1.1: icmp_seq=4 ttl=55 time=12.3 ms

--- 1.1.1.1 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3005ms
rtt min/avg/max/mdev = 9.766/14.397/19.823/3.785 ms
```

## 9 Trace Analysis

Now that we have captured control plane and user plane traces, we can stop `tshark`:
``` shell
docker-compose-host $: sudo pkill tshark
```

Then, we change the permissions of the traces to open them in Wireshark:
``` shell
docker-compose-host $: sudo chmod 666 /tmp/oai/ulcl-scenario/control_plane.pcap
docker-compose-host $: sudo chmod 666 /tmp/oai/ulcl-scenario/user_plane_ulcl.pcap
docker-compose-host $: sudo chmod 666 /tmp/oai/ulcl-scenario/user_plane_edge_only.pcap
docker-compose-host $: sudo chmod 666 /tmp/oai/ulcl-scenario/user_plane_internet_only.pcap
```

As we capture more than one interface, the pcap files are likely out-of-order. To solve this, sort based on the `Time`
column. 

### UL CL Scenario

First, we open the `user_plane_ulcl.pcap` file, apply the filter `icmp` and sort based on time. 

We see that each ICMP request to 8.8.8.8 has four packets. The first is from the gNB to the UL CL, the second is from the
ULCL to the A-UPF2, the third is from A-UPF2 to EXT-DN-Edge. The last packet is from the EXT-DN-Edge to the Internet.
We see that here NAT is applied and the UE source IP `12.1.1.2` is replaced with `192.168.76.160`, the IP address of the 
EXT-DN-Edge. The same happens for the ICMP reply, but in the other direction.

It is interesting to check the first IP layer and the GTP layer. Here, we see based on the source and destination IP addresses
that the packet is indeed following the expected route.

When we analyze the ICMP request to 1.1.1.1., we can see that the path from the gNB to the UL CL is the same. After that, 
however, the packets are routed via the A-UPF1 (`192.168.73.202`). Therefore, the EXT-DN-Internet is used and NAT happens
at the IP address `192.168.75.160`.

### Edge Only Scenario

We open the `user_plane_edge_only.pcap` file and apply the same filter and sorting.

We see that the ICMP traffic to 8.8.8.8 follows the edge route, as in the previous example. The difference is that
other ICMP traffic is routed over the edge as well. In fact, all traffic is routed there, as it is defined in the
PCC rules.

### Internet Only Scenario

We open the `user_plane_internet_only.pcap` file and apply the same filter and sorting.

This scenario is the opposite of the edge-only scenario. We can see that all the traffic is routed to A-UPF1 and the
EXT-DN-Internet. 

## 10 Undeploy Network Functions

When you are done, you can undeploy the gnbsim instances and all the NFs.

Before doing that, we collect the logs:

``` shell
docker-compose-host $: docker logs oai-amf > /tmp/oai/ulcl-scenario/amf.log 2>&1
docker-compose-host $: docker logs oai-smf > /tmp/oai/ulcl-scenario/smf.log 2>&1
docker-compose-host $: docker logs oai-nrf > /tmp/oai/ulcl-scenario/nrf.log 2>&1
docker-compose-host $: docker logs vpp-upf-ulcl > /tmp/oai/ulcl-scenario/vpp-upf-ulcl.log 2>&1
docker-compose-host $: docker logs vpp-upf-aupf1 > /tmp/oai/ulcl-scenario/vpp-upf-aupf1.log 2>&1
docker-compose-host $: docker logs vpp-upf-aupf2 > /tmp/oai/ulcl-scenario/vpp-upf-aupf2.log 2>&1
docker-compose-host $: docker logs oai-udr > /tmp/oai/ulcl-scenario/udr.log 2>&1
docker-compose-host $: docker logs oai-udm > /tmp/oai/ulcl-scenario/udm.log 2>&1
docker-compose-host $: docker logs oai-ausf > /tmp/oai/ulcl-scenario/ausf.log 2>&1
docker-compose-host $: docker logs gnbsim-vpp > /tmp/oai/ulcl-scenario/gnbsim-vpp.log 2>&1
docker-compose-host $: docker logs gnbsim-vpp2 > /tmp/oai/ulcl-scenario/gnbsim-vpp2.log 2>&1
docker-compose-host $: docker logs gnbsim-vpp3 > /tmp/oai/ulcl-scenario/gnbsim-vpp3.log 2>&1
```



First, we shut down the gnbsims:
``` shell
docker-compose-host $: docker-compose -f docker-compose-gnbsim-vpp-additional.yaml down
docker-compose-host $: docker-compose -f docker-compose-gnbsim-vpp.yaml down
```

Finally, we can undeploy the 5GCN NFs:

``` shell
docker-compose-host $: docker-compose -f docker-compose-basic-vpp-pcf-ulcl.yaml down
```

## 11 Conclusion
We showed in this tutorial how the UL CL can be configured in the OAI. The UL CL UPF is acting as an UL CL for the first scenario,
but is acting as an I-UPF for the edge-only and internet-only scenario.

You can see in the `docker-compose-basic-vpp-pcf-ulcl.yaml`
file and the policy configuration that the DNAI and NW instances have to be configured correctly in UPF and PCF.

As an example, the `internet-scenario` traffic rule has the following DNAIs configured:
* access
* ulcl
* aupf1
* internet

This means that each of these components should be present in the path, i.e. gNB (access), ULCL UPF (ulcl), AUPF1(aupf1)
and EXT-DN-Internet (internet).

We can see in the configuration of the UL CL UPF that the N3 interface configures the `access` DNAI and the N9 interface to the
AUPF1 configures the `aupf1` DNAI. The N9 interface of the A-UPF1 configures the `ulcl` DNAI and the N6 interface the `internet` DNAI.

The naming of the DNAIs is up to the user, but we recommend that it should correspond to the name of the NF.

When the SMF is creating the UPF graph, the edges are created based on the NWI of a UPF interface and the UPF FQDN.

For example, the ULCL UPF configures the NWI `aupf1.node.5gcn.mnc95.mcc208.3gppnetwork.org` for its N9 interface to the
A-UPF1. An edge exists when the FQDN of the A-UPF matches this string. The FQDN is not directly configured, but is composed
of different environment variables:

`<NAME>.node.5gcn.mnc<MNC>.mcc<MCC>.<REALM>`

Keep that in mind when creating your own scenarios and always verify in the SMF logs that the graph is built correctly.
