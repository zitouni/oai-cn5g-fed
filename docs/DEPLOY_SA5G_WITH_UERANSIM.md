<table style="border-collapse: collapse; border: none;">
  <tr style="border-collapse: collapse; border: none;">
    <td style="border-collapse: collapse; border: none;">
      <a href="http://www.openairinterface.org/">
         <img src="./images/oai_final_logo.png" alt="" border=3 height=50 width=150>
         </img>
      </a>
    </td>
    <td style="border-collapse: collapse; border: none; vertical-align: center;">
      <b><font size = "5">OpenAirInterface 5G Core Network Deployment and Testing with UERANSIM</font></b>
    </td>
  </tr>
</table>


![SA dsTest Demo](./images/5gcn_vpp_upf_ueransim.png)

**Reading time: ~ 30mins**

**Tutorial replication time: ~ 1h30mins**

Note: In case readers are interested in deploying debuggers/developers core network environment with more logs please follow [this tutorial](./DEBUG_5G_CORE.md)

**TABLE OF CONTENTS**

1.  Pre-requisites
2.  Building Container Images
3.  Configuring Host Machines
4.  Configuring OAI 5G Core Network Functions
5.  Deploying OAI 5G Core Network
6.  [Getting a `ueransim` docker image](#6-getting-a-ueransim-docker-image)
7.  [Executing `ueransim` Scenario](#7-executing-the-ueransim-scenario)
8.  [Analysing Scenario Results](#8-analysing-the-scenario-results)

* In this demo the image tags and commits which were used are listed below, follow the [Building images](./BUILD_IMAGES.md) to build images with below tags.

| CNF Name    | Branch Name | Tag      | Ubuntu 18.04 | RHEL8 (UBI8)    |
| ----------- | ----------- | -------- | ------------ | ----------------|
| AMF         | `develop`   | `v1.2.0` | X            | X               |
| SMF         | `develop`   | `v1.2.0` | X            | X               |
| NRF         | `develop`   | `v1.2.0` | X            | X               |
| VPP-UPF     | `develop`   | `v1.1.3` | X            | X               |
| UDR         | `develop`   | `v1.2.0` | X            | X               |
| UDM         | `develop`   | `v1.2.0` | X            | X               |
| AUSF        | `develop`   | `v1.2.0` | X            | X               |

<br/>

This tutorial is an extension of a previous tutorial: [testing a `basic` deployment with dsTester](./DEPLOY_SA5G_BASIC_DS_TESTER_DEPLOYMENT.md). In previous tutorial, we have seen the advanced testing tool dsTester, which is useful for validating even more complex scenarios.

Moreover, there are various other opensource gnb/ue simulator tools that are available for SA5G test. In this tutorial, we use an opensource simulator tool called `UERANSIM`. With the help of `UERANSIM` tool, we can perform very basic SA5G test by simulating one gnb and multiple ues.

##### About UERANSIM -

[UERANSIM](https://github.com/aligungr/UERANSIM) is the open-source state-of-the-art 5G UE and RAN (gNodeB) implementation). It can be considered as a 5G mobile phone and a base station in basic terms. The project can be used for testing 5G Core Network and studying 5G System. UERANSIM can simulate multiple UEs and it also aims to simulate radio. Moreover for detailed feature set, please refer its [official page.](https://github.com/aligungr/UERANSIM/wiki/Feature-Set)

Let's begin !!

* Steps 1 to 5 are similar as previous [tutorial on vpp-upf](https://gitlab.eurecom.fr/oai/cn5g/oai-cn5g-fed/-/blob/master/docs/DEPLOY_SA5G_WITH_VPP_UPF.md#5-deploying-oai-5g-core-network). Please follow these steps to deploy OAI 5G core network components.
* We depoloy ueransim docker service on same host as of core network, so there is no need to create additional route as
we did for dsTest-host.
* Before we proceed further for end-to-end SA5G test, make sure you have healthy docker services for OAI cn5g

#### NOTE: #### 
UERANSIM currently does not support integraty and ciphering algorithm NIA0, NEA0 repectively. Hence we have to update AMF config in the docker-compose as below -

Add following parametrs in oai-amf service of docker-compose
```bash
            - INT_ALGO_LIST=["NIA1" , "NIA2"]
            - CIPH_ALGO_LIST=["NEA1" , "NEA2"]
```

Then we follow deployment procedure as usual.
```bash
oai-cn5g-fed/docker-compose$  python3 ./core-network.py --type start-basic-vpp --fqdn no --scenario 1
...
[2021-09-14 16:44:47,176] root:DEBUG:  OAI 5G Core network is configured and healthy....
```

More details in [section 5 of the `basic` vpp tutorial](https://gitlab.eurecom.fr/oai/cn5g/oai-cn5g-fed/-/blob/master/docs/DEPLOY_SA5G_WITH_VPP_UPF.md#5-deploying-oai-5g-core-network).

```bash
oai-cn5g-fed/docker-compose$ docker ps -a
CONTAINER ID   IMAGE                COMMAND                  CREATED          STATUS                    PORTS                          NAMES
4349e8808902   oai-smf:latest       "/bin/bash /openair-…"   49 seconds ago   Up 48 seconds (healthy)   80/tcp, 9090/tcp, 8805/udp     oai-smf
62e774768482   oai-amf:latest       "/bin/bash /openair-…"   49 seconds ago   Up 48 seconds (healthy)   80/tcp, 9090/tcp, 38412/sctp   oai-amf
0302e6a3d2b3   oai-ausf:latest      "/bin/bash /openair-…"   50 seconds ago   Up 49 seconds (healthy)   80/tcp                         oai-ausf
fb3249a5ade7   ubuntu:bionic        "/bin/bash -c ' apt …"   51 seconds ago   Up 49 seconds                                            oai-ext-dn
4f114039c218   oai-udm:latest       "/bin/bash /openair-…"   51 seconds ago   Up 49 seconds (healthy)   80/tcp                         oai-udm
c0838aff8796   oai-udr:latest       "/bin/bash /openair-…"   51 seconds ago   Up 50 seconds (healthy)   80/tcp                         oai-udr
99ab1b23862c   oai-upf-vpp:latest   "/openair-upf/bin/en…"   51 seconds ago   Up 50 seconds (healthy)   2152/udp, 8085/udp             vpp-upf
3469f853e26d   mysql:5.7            "docker-entrypoint.s…"   52 seconds ago   Up 51 seconds (healthy)   3306/tcp, 33060/tcp            mysql
ab06bd3104ef   oai-nrf:latest       "/bin/bash /openair-…"   52 seconds ago   Up 51 seconds (healthy)   80/tcp, 9090/tcp               oai-nrf
```

## 6. Getting a `UERANSIM` docker image ##

You have the choice:

* Build `UERANSIM` docker image

```bash
$ git clone -B docker_support https://github.com/orion-belt/UERANSIM.git
$ cd UERANSIM
$  docker build --target ueransim --tag ueransim:latest -f docker/Dockerfile.ubuntu.18.04 .
```

OR

* You can pull a prebuilt docker image for `UERANSIM`

```bash
docker pull rohankharade/ueransim
docker image tag rohankharade/ueransim:latest ueransim:latest
```

## 7. Executing the `UERANSIM` Scenario ##

* The configuration parameters, are preconfigured in [docker-compose.yaml](../docker-compose/docker-compose.yaml) and [docker-compose.yaml OF UERANSIM](https://github.com/orion-belt/UERANSIM/blob/docker_support/docker/docker-compose.yamll) and one can modify it for test.
* Launch ueransim docker service
```bash
UERANSIM$ docker-compose -f docker/docker-compose-vpp.yaml up -d
Creating ueransim ... done
```
* After launching UERANSIM, make sure all services status are healthy -
```bash
oai-cn5g-fed/docker-compose$ docker ps -a
CONTAINER ID   IMAGE                COMMAND                  CREATED              STATUS                        PORTS                          NAMES
cb206b9b0a25   ueransim:latest      "/ueransim/bin/entry…"   14 seconds ago       Up 13 seconds (healthy)                                      ueransim
4349e8808902   oai-smf:latest       "/bin/bash /openair-…"   About a minute ago   Up About a minute (healthy)   80/tcp, 9090/tcp, 8805/udp     oai-smf
62e774768482   oai-amf:develop      "/bin/bash /openair-…"   About a minute ago   Up About a minute (healthy)   80/tcp, 9090/tcp, 38412/sctp   oai-amf
0302e6a3d2b3   oai-ausf:latest      "/bin/bash /openair-…"   About a minute ago   Up About a minute (healthy)   80/tcp                         oai-ausf
fb3249a5ade7   ubuntu:bionic        "/bin/bash -c ' apt …"   About a minute ago   Up About a minute                                            oai-ext-dn
4f114039c218   oai-udm:latest       "/bin/bash /openair-…"   About a minute ago   Up About a minute (healthy)   80/tcp                         oai-udm
c0838aff8796   oai-udr:latest       "/bin/bash /openair-…"   About a minute ago   Up About a minute (healthy)   80/tcp                         oai-udr
99ab1b23862c   oai-upf-vpp:latest   "/openair-upf/bin/en…"   About a minute ago   Up About a minute (healthy)   2152/udp, 8085/udp             vpp-upf
3469f853e26d   mysql:5.7            "docker-entrypoint.s…"   About a minute ago   Up About a minute (healthy)   3306/tcp, 33060/tcp            mysql
ab06bd3104ef   oai-nrf:latest       "/bin/bash /openair-…"   About a minute ago   Up About a minute (healthy)   80/tcp, 9090/tcp               oai-nrf
```
We can verify it using UERANSIM container logs as below -
```bash
$ docker logs ueransim
Now setting these variables '@GTP_IP@ @IGNORE_STREAM_IDS@ @LINK_IP@ @MCC@ @MNC@ @NCI@ @NGAP_IP@ @NGAP_PEER_IP@ @SD@ @SST@ @TAC@'
Now setting these variables '@AMF_VALUE@ @APN@ @GNB_IP_ADDRESS@ @IMEI@ @IMEI_SV@ @IMSI@ @KEY@ @MCC@ @MNC@ @OP@ @OP_TYPE@ @PDU_TYPE@ @SD@ @SD_C@ @SD_D@ @SST@ @SST_C@ @SST_D@'
Done setting the configuration
### Running ueransim ###
Running gnb
UERANSIM v3.2.4
[2021-12-01 07:46:01.772] [sctp] [info] Trying to establish SCTP connection... (192.168.70.132:38412)
[2021-12-01 07:46:01.776] [sctp] [info] SCTP connection established (192.168.70.132:38412)
[2021-12-01 07:46:01.776] [sctp] [debug] SCTP association setup ascId[105]
[2021-12-01 07:46:01.776] [ngap] [debug] Sending NG Setup Request
[2021-12-01 07:46:01.780] [ngap] [debug] NG Setup Response received
[2021-12-01 07:46:01.780] [ngap] [info] NG Setup procedure is successful
Running ue
UERANSIM v3.2.4
[2021-12-01 07:46:02.759] [nas] [info] UE switches to state [MM-DEREGISTERED/PLMN-SEARCH]
[2021-12-01 07:46:02.759] [rrc] [debug] UE[1] new signal detected
[2021-12-01 07:46:02.759] [rrc] [debug] New signal detected for cell[1], total [1] cells in coverage
[2021-12-01 07:46:02.759] [nas] [info] Selected plmn[208/95]
[2021-12-01 07:46:02.759] [rrc] [info] Selected cell plmn[208/95] tac[40960] category[SUITABLE]
[2021-12-01 07:46:02.759] [nas] [info] UE switches to state [MM-DEREGISTERED/PS]
[2021-12-01 07:46:02.759] [nas] [info] UE switches to state [MM-DEREGISTERED/NORMAL-SERVICE]
[2021-12-01 07:46:02.759] [nas] [debug] Initial registration required due to [MM-DEREG-NORMAL-SERVICE]
[2021-12-01 07:46:02.759] [nas] [debug] UAC access attempt is allowed for identity[0], category[MO_sig]
[2021-12-01 07:46:02.759] [nas] [debug] Sending Initial Registration
[2021-12-01 07:46:02.760] [nas] [info] UE switches to state [MM-REGISTER-INITIATED]
[2021-12-01 07:46:02.760] [rrc] [debug] Sending RRC Setup Request
[2021-12-01 07:46:02.760] [rrc] [info] RRC Setup for UE[1]
[2021-12-01 07:46:02.760] [rrc] [info] RRC connection established
[2021-12-01 07:46:02.760] [rrc] [info] UE switches to state [RRC-CONNECTED]
[2021-12-01 07:46:02.760] [nas] [info] UE switches to state [CM-CONNECTED]
[2021-12-01 07:46:02.760] [ngap] [debug] Initial NAS message received from UE[1]
[2021-12-01 07:46:02.787] [nas] [debug] Authentication Request received
[2021-12-01 07:46:02.799] [nas] [debug] Security Mode Command received
[2021-12-01 07:46:02.799] [nas] [debug] Selected integrity[1] ciphering[1]
[2021-12-01 07:46:02.804] [ngap] [debug] Initial Context Setup Request received
[2021-12-01 07:46:02.805] [nas] [debug] Registration accept received
[2021-12-01 07:46:02.805] [nas] [info] UE switches to state [MM-REGISTERED/NORMAL-SERVICE]
[2021-12-01 07:46:02.805] [nas] [debug] Sending Registration Complete
[2021-12-01 07:46:02.805] [nas] [info] Initial Registration is successful
[2021-12-01 07:46:02.805] [nas] [debug] Sending PDU Session Establishment Request
[2021-12-01 07:46:02.805] [nas] [debug] UAC access attempt is allowed for identity[0], category[MO_sig]
[2021-12-01 07:46:03.036] [ngap] [info] PDU session resource(s) setup for UE[1] count[1]
[2021-12-01 07:46:03.037] [nas] [debug] PDU Session Establishment Accept received
[2021-12-01 07:46:03.037] [nas] [info] PDU Session establishment is successful PSI[1]
[2021-12-01 07:46:03.055] [app] [info] Connection setup for PDU session[1] is successful, TUN interface[uesimtun0, 12.1.1.2] is up.
```
Now we are ready to perform some traffic test.
* Ping test <br/>
Here we ping UE from external DN container.
```bash
$ docker exec -it oai-ext-dn ping -c 3 12.1.1.2
PING 12.1.1.2 (12.1.1.2) 56(84) bytes of data.
64 bytes from 12.1.1.2: icmp_seq=1 ttl=64 time=0.235 ms
64 bytes from 12.1.1.2: icmp_seq=2 ttl=64 time=0.145 ms
64 bytes from 12.1.1.2: icmp_seq=3 ttl=64 time=0.448 ms

--- 12.1.1.2 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2036ms
rtt min/avg/max/mdev = 0.145/0.276/0.448/0.127 ms
```
Here we ping external DN from UE (UERANSIM) container.
```bash
oai-cn5g-fed/docker-compose$ docker exec ueransim ping -I uesimtun0 google.com
PING google.com (172.217.18.238) from 12.1.1.2 : 56(84) bytes of data.
64 bytes from par10s10-in-f238.1e100.net (172.217.18.238): icmp_seq=1 ttl=115 time=5.12 ms
64 bytes from par10s10-in-f238.1e100.net (172.217.18.238): icmp_seq=2 ttl=115 time=7.52 ms
64 bytes from par10s10-in-f238.1e100.net (172.217.18.238): icmp_seq=3 ttl=115 time=7.19 ms

--- google.com ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 4ms
rtt min/avg/max/mdev = 5.119/6.606/7.515/1.064 ms
```

* Iperf test <br/>
Here we do iperf traffic test between UERANSIM UE and external DN node. We can make any node as iperf server/client.<br/>
Running iperf server on external DN container
```bash
$ docker exec -it oai-ext-dn iperf3 -s 
-----------------------------------------------------------
Server listening on 5201
-----------------------------------------------------------
Accepted connection from 12.1.1.3, port 49925
[  5] local 192.168.73.135 port 5201 connected to 12.1.1.2 port 58455
[ ID] Interval           Transfer     Bandwidth
[  5]   0.00-1.00   sec  4.13 MBytes  34.6 Mbits/sec                  
[  5]   1.00-2.00   sec  2.33 MBytes  19.5 Mbits/sec                  
[  5]   2.00-3.00   sec  2.68 MBytes  22.5 Mbits/sec                  
[  5]   3.00-4.00   sec  2.10 MBytes  17.6 Mbits/sec                  
[  5]   4.00-5.00   sec  2.26 MBytes  19.0 Mbits/sec                  
[  5]   5.00-6.00   sec  2.14 MBytes  17.9 Mbits/sec                  
[  5]   6.00-7.00   sec  2.71 MBytes  22.8 Mbits/sec                  
[  5]   7.00-8.00   sec  2.19 MBytes  18.4 Mbits/sec                  
[  5]   8.00-9.00   sec  2.12 MBytes  17.8 Mbits/sec                  
[  5]   9.00-10.00  sec  2.53 MBytes  21.2 Mbits/sec                  
[  5]  10.00-10.00  sec  0.00 Bytes  0.00 bits/sec                  
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bandwidth
[  5]   0.00-10.00  sec  0.00 Bytes  0.00 bits/sec                  sender
[  5]   0.00-10.00  sec  25.2 MBytes  21.1 Mbits/sec                  receiver
-----------------------------------------------------------
Server listening on 5201
-----------------------------------------------------------
```
Running iperf client on ueransim
```bash
$ docker exec -it ueransim iperf3 -c 192.168.73.135 -B 12.1.1.2
Connecting to host 192.168.73.135, port 5201
[  4] local 12.1.1.2 port 58455 connected to 192.168.73.135 port 5201
[ ID] Interval           Transfer     Bandwidth       Retr  Cwnd
[  4]   0.00-1.00   sec  5.07 MBytes  42.5 Mbits/sec  318   34.2 KBytes       
[  4]   1.00-2.00   sec  2.34 MBytes  19.7 Mbits/sec  268   22.4 KBytes       
[  4]   2.00-3.00   sec  2.72 MBytes  22.8 Mbits/sec  276   34.2 KBytes       
[  4]   3.00-4.00   sec  2.10 MBytes  17.6 Mbits/sec  234   38.2 KBytes       
[  4]   4.00-5.00   sec  2.22 MBytes  18.6 Mbits/sec  303   13.2 KBytes       
[  4]   5.00-6.00   sec  2.16 MBytes  18.1 Mbits/sec  240   38.2 KBytes       
[  4]   6.00-7.00   sec  2.72 MBytes  22.8 Mbits/sec  307   60.6 KBytes       
[  4]   7.00-8.00   sec  2.16 MBytes  18.1 Mbits/sec  325   35.5 KBytes       
[  4]   8.00-9.00   sec  2.16 MBytes  18.1 Mbits/sec  223   56.6 KBytes       
[  4]   9.00-10.00  sec  2.47 MBytes  20.7 Mbits/sec  349   26.3 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bandwidth       Retr
[  4]   0.00-10.00  sec  26.1 MBytes  21.9 Mbits/sec  2843             sender
[  4]   0.00-10.00  sec  25.2 MBytes  21.1 Mbits/sec                  receiver

iperf Done.
```
* Note:- The iperf test is just for illustration purpose and results of the test may vary based on resources available for the docker services

## 8. Analysing the Scenario Results ##

| Pcap/log files                                                                             |
|:------------------------------------------------------------------------------------------ |
| [5gcn-deployment-ueransim.pcap](./results/UERANSIM/pcap/5gcn-deployment-ueransim.pcap)                  |


* For detailed analysis of messages, please refer previous tutorial of [testing with dsTester](./docs/DEPLOY_SA5G_WITH_DS_TESTER.md).

## 9. Undeploy ##

Last thing is to remove all services - <br/>

* Undeploy the UERANSIM
```bash
UERANSIM$ docker-compose -f docker-compose-vpp.yaml down
Stopping ueransim ... done
Removing ueransim ... done
Network demo-oai-public-net is external, skipping
Network oai-public-access is external, skipping
```

* Undeploy the core network
```bash
oai-cn5g-fed/docker-compose$  python3 ./core-network.py --type stop-basic-vpp --fqdn no --scenario 1
...
[2021-09-14 16:47:44,070] root:DEBUG:  OAI 5G core components are UnDeployed....
```


