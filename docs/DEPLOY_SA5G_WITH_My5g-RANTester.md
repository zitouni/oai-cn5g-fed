<table style="border-collapse: collapse; border: none;">
  <tr style="border-collapse: collapse; border: none;">
    <td style="border-collapse: collapse; border: none;">
      <a href="http://www.openairinterface.org/">
         <img src="./images/oai_final_logo.png" alt="" border=3 height=50 width=150>
         </img>
      </a>
    </td>
    <td style="border-collapse: collapse; border: none; vertical-align: center;">
      <b><font size = "5">OpenAirInterface 5G Core Network Deployment and Testing with My5g-RANTester</font></b>
    </td>
  </tr>
</table>


![SA dsTest Demo](./images/5gcn_vpp_upf_my5grantester.png)

**Reading time: ~ 30mins**

**Tutorial replication time: ~ 1h30mins**

Note: In case readers are interested in deploying debuggers/developers core network environment with more logs please follow [this tutorial](./DEBUG_5G_CORE.md)

**TABLE OF CONTENTS**

1.  Pre-requisites
2.  Building Container Images
3.  Configuring Host Machines
4.  Configuring OAI 5G Core Network Functions
5.  Deploying OAI 5G Core Network
6.  [Getting a `my5G-RANTester` docker image](#6-getting-a-my5G-RANTester-docker-image)
7.  [Executing `my5G-RANTester` Scenario](#7-executing-the-my5G-RANTester-scenario)
8.  [Analysing Scenario Results](#8-analysing-the-scenario-results)
9.  [Trying some advanced stuff](#9-trying-some-advanced-stuff)

* In this demo the image tags and commits which were used are listed below, follow the [Building images](./BUILD_IMAGES.md) to build images with below tags.

| CNF Name    | Branch Name | Tag      | Ubuntu 18.04 | RHEL8 (UBI8)    |
| ----------- | ----------- | -------- | ------------ | ----------------|
| AMF         | `develop`   | `v1.3.0` | X            | X               |
| SMF         | `develop`   | `v1.3.0` | X            | X               |
| NRF         | `develop`   | `v1.3.0` | X            | X               |
| VPP-UPF     | `develop`   | `v1.3.0` | X            | X               |
| UDR         | `develop`   | `v1.3.0` | X            | X               |
| UDM         | `develop`   | `v1.3.0` | X            | X               |
| AUSF        | `develop`   | `v1.3.0` | X            | X               |

<br/>

This tutorial is an extension of a previous tutorial: [testing a `basic` deployment with dsTester](./DEPLOY_SA5G_BASIC_DS_TESTER_DEPLOYMENT.md). In previous tutorial, we have seen the advanced testing tool dsTester, which is useful for validating even more complex scenarios.

Moreover, there are various other opensource gnb/ue simulator tools that are available for SA5G test. In this tutorial, we use an opensource simulator tool called `My5g-RANTester`. With the help of `My5g-RANTester` tool, we can perform very basic SA5G test by simulating one gnb and multiple ues.

##### About My5g-RANTester -

[My5g-RANTester](https://github.com/my5G/my5G-RANTester) is the open-source state-of-the-art 5G UE and RAN (gNodeB) implementation. my5G-RANTester follows the 3GPP Release 15 standard for NG-RAN. Using my5G-RANTester, it is possible to generate different workloads and test several functionalities of a 5G core, including its complaince to the 3GPP standards. Scalability is also a relevant feature of the my5G-RANTester, which is able mimic the behaviour of a large number of UEs and gNBs accessing simultaneously a 5G core.

Let's begin !!

* Steps 1 to 5 are similar as previous [tutorial on vpp-upf](https://gitlab.eurecom.fr/oai/cn5g/oai-cn5g-fed/-/blob/master/docs/DEPLOY_SA5G_WITH_VPP_UPF.md#5-deploying-oai-5g-core-network). Please follow these steps to deploy OAI 5G core network components.
* We deploy my5G-RANTester docker service on same host as of core network, so there is no need to create additional route as
we did for dsTest-host.
* Before we proceed further for end-to-end SA5G test, make sure you have healthy docker services for OAI cn5g


Then we follow deployment procedure as usual.
```shell
docker-compose-host $: cd oai-cn5g-fed/docker-compose
docker-compose-host $: docker-compose -f docker-compose-basic-vpp-nrf.yaml up -d
Creating mysql   ... done
Creating oai-nrf ... done
Creating vpp-upf ... done
Creating oai-udr ... done
Creating oai-udm    ... done
Creating oai-ext-dn ... done
Creating oai-ausf   ... done
Creating oai-amf    ... done
Creating oai-smf    ... done
```

More details in [section 5 of the `basic` vpp tutorial](https://gitlab.eurecom.fr/oai/cn5g/oai-cn5g-fed/-/blob/master/docs/DEPLOY_SA5G_WITH_VPP_UPF.md#5-deploying-oai-5g-core-network).
After deploying core network, make sure all services are healthy.

```shell
docker-compose-host $: docker ps -a
CONTAINER ID   IMAGE                COMMAND                  CREATED              STATUS                        PORTS                          NAMES
0c0f6920aedf   oai-smf:latest       "/bin/bash /openair-…"   About a minute ago   Up About a minute (healthy)   80/tcp, 9090/tcp, 8805/udp     oai-smf
1eca41c99ceb   oai-amf:latest       "/bin/bash /openair-…"   About a minute ago   Up About a minute (healthy)   80/tcp, 9090/tcp, 38412/sctp   oai-amf
96956aa69cf8   oai-ausf:latest      "/bin/bash /openair-…"   About a minute ago   Up About a minute (healthy)   80/tcp                         oai-ausf
7c0c07f63ad6   ubuntu:bionic        "/bin/bash -c ' apt …"   About a minute ago   Up About a minute                                            oai-ext-dn
daa71ea02f62   oai-udm:latest       "/bin/bash /openair-…"   About a minute ago   Up About a minute (healthy)   80/tcp                         oai-udm
9afe69c737d9   oai-udr:latest       "/bin/bash /openair-…"   About a minute ago   Up About a minute (healthy)   80/tcp                         oai-udr
6faa329c97f9   oai-upf-vpp:latest   "/openair-upf/bin/en…"   About a minute ago   Up About a minute (healthy)   2152/udp, 8085/udp             vpp-upf
8cf8bcb54725   mysql:5.7            "docker-entrypoint.s…"   About a minute ago   Up About a minute (healthy)   3306/tcp, 33060/tcp            mysql
8e8037f2aadb   oai-nrf:latest       "/bin/bash /openair-…"   About a minute ago   Up About a minute (healthy)   80/tcp, 9090/tcp               oai-nrf
```

## 6. Building a `My5g-RANTester` docker image ##
* Pull pre-built docker image 
```shell
docker-compose-host $: docker pull rohankharade/my5grantester:latest
docker-compose-host $: docker tag rohankharade/my5grantester:latest my5grantester:latest
```

OR 

* Build `My5g-RANTester` docker image
```shell
docker-compose-host $: git clone https://github.com/my5G/my5G-RANTester
docker-compose-host $: cd my5G-RANTester/
docker-compose-host $: docker build -f docker/Dockerfile --target my5grantester --tag my5grantester:latest .
```


## 7. Executing the `My5g-RANTester` Scenario ##

* The configuration parameters, are preconfigured in [docker-compose-basic-vpp-nrf.yaml](../docker-compose/docker-compose-basic-vpp-nrf.yaml) and [docker-compose-my5grantester-vpp.yaml](../docker-compose/docker-compose-my5grantester-vpp.yaml) and one can modify it for test.
* Launch my5G-RANTester docker service
```shell
docker-compose-host $: cd oai-cn5g-fed/docker-compose
docker-compose-host $: docker-compose -f docker-compose-my5grantester-vpp.yaml up -d
Creating my5grantester ... done
```
* After launching My5g-RANTester, make sure service status is healthy -
```shell
docker-compose-host $: docker-compose -f docker-compose-my5grantester-vpp.yaml ps -a
    Name        Command       State       Ports
-----------------------------------------------
my5grantester   ./app ue   Up (healthy)        
```

We can verify it using my5grantester container logs as below -
```shell
docker-compose-host $: docker logs my5G-RANTester
Creating my5grantester ... done
Attaching to my5grantester
my5grantester    | time="2022-05-11T21:59:28Z" level=info msg="my5G-RANTester version 0.1"
my5grantester    | time="2022-05-11T21:59:28Z" level=info msg=---------------------------------------
my5grantester    | time="2022-05-11T21:59:28Z" level=info msg="[TESTER] Starting test function: Testing registration of multiple UEs"
my5grantester    | time="2022-05-11T21:59:28Z" level=info msg="[TESTER][UE] Number of UEs: 1"
my5grantester    | time="2022-05-11T21:59:28Z" level=info msg="[TESTER][GNB] gNodeB control interface IP/Port: 192.168.70.143/9487"
my5grantester    | time="2022-05-11T21:59:28Z" level=info msg="[TESTER][GNB] gNodeB data interface IP/Port: 192.168.72.143/2152"
my5grantester    | time="2022-05-11T21:59:28Z" level=info msg="[TESTER][AMF] AMF IP/Port: 192.168.70.132/38412"
my5grantester    | time="2022-05-11T21:59:28Z" level=info msg=---------------------------------------
my5grantester    | time="2022-05-11T21:59:28Z" level=info msg="[GNB] SCTP/NGAP service is running"
my5grantester    | time="2022-05-11T21:59:28Z" level=info msg="[GNB] UNIX/NAS service is running"
my5grantester    | time="2022-05-11T21:59:28Z" level=info msg="[GNB][SCTP] Receive message in 0 stream\n"
my5grantester    | time="2022-05-11T21:59:28Z" level=info msg="[GNB][NGAP] Receive Ng Setup Response"
my5grantester    | time="2022-05-11T21:59:28Z" level=info msg="[GNB][AMF] AMF Name: OAI-AMF"
my5grantester    | time="2022-05-11T21:59:28Z" level=info msg="[GNB][AMF] State of AMF: Active"
my5grantester    | time="2022-05-11T21:59:28Z" level=info msg="[GNB][AMF] Capacity of AMF: 30"
my5grantester    | time="2022-05-11T21:59:28Z" level=info msg="[GNB][AMF] PLMNs Identities Supported by AMF -- mcc: 208 mnc:95"
my5grantester    | time="2022-05-11T21:59:28Z" level=info msg="[GNB][AMF] List of AMF slices Supported by AMF -- sst:de sd:000000"
my5grantester    | time="2022-05-11T21:59:28Z" level=info msg="[GNB][AMF] List of AMF slices Supported by AMF -- sst:01 sd:000001"
my5grantester    | time="2022-05-11T21:59:28Z" level=info msg="[GNB][AMF] List of AMF slices Supported by AMF -- sst:04 sd:000000"
my5grantester    | time="2022-05-11T21:59:29Z" level=info msg="[TESTER] TESTING REGISTRATION USING IMSI 0000000043 UE"
my5grantester    | time="2022-05-11T21:59:29Z" level=info msg="[UE] UNIX/NAS service is running"
my5grantester    | time="2022-05-11T21:59:29Z" level=info msg="[GNB][SCTP] Receive message in 0 stream\n"
my5grantester    | time="2022-05-11T21:59:29Z" level=info msg="[GNB][NGAP] Receive Downlink NAS Transport"
my5grantester    | time="2022-05-11T21:59:29Z" level=info msg="[UE][NAS] Message without security header"
my5grantester    | time="2022-05-11T21:59:29Z" level=info msg="[UE][NAS] Receive Authentication Request"
my5grantester    | time="2022-05-11T21:59:29Z" level=info msg="[UE][NAS][MAC] Authenticity of the authentication request message: OK"
my5grantester    | time="2022-05-11T21:59:29Z" level=info msg="[UE][NAS][SQN] SQN of the authentication request message: VALID"
my5grantester    | time="2022-05-11T21:59:29Z" level=info msg="[UE][NAS] Send authentication response"
my5grantester    | time="2022-05-11T21:59:29Z" level=info msg="[GNB][SCTP] Receive message in 0 stream\n"
my5grantester    | time="2022-05-11T21:59:29Z" level=info msg="[GNB][NGAP] Receive Downlink NAS Transport"
my5grantester    | time="2022-05-11T21:59:29Z" level=info msg="[UE][NAS] Message with security header"
my5grantester    | time="2022-05-11T21:59:29Z" level=info msg="[UE][NAS] Message with integrity and with NEW 5G NAS SECURITY CONTEXT"
my5grantester    | time="2022-05-11T21:59:29Z" level=info msg="[UE][NAS] successful NAS MAC verification"
my5grantester    | time="2022-05-11T21:59:29Z" level=info msg="[UE][NAS] Receive Security Mode Command"
my5grantester    | time="2022-05-11T21:59:29Z" level=info msg="[UE][NAS] Type of ciphering algorithm is 5G-EA0"
my5grantester    | time="2022-05-11T21:59:29Z" level=info msg="[UE][NAS] Type of integrity protection algorithm is 128-5G-IA2"
my5grantester    | time="2022-05-11T21:59:29Z" level=info msg="[GNB][SCTP] Receive message in 0 stream\n"
my5grantester    | time="2022-05-11T21:59:29Z" level=info msg="[GNB][NGAP] Receive Initial Context Setup Request"
my5grantester    | time="2022-05-11T21:59:29Z" level=info msg="[GNB][UE] UE Context was created with successful"
my5grantester    | time="2022-05-11T21:59:29Z" level=info msg="[GNB][UE] UE RAN ID 1"
my5grantester    | time="2022-05-11T21:59:29Z" level=info msg="[GNB][UE] UE AMF ID 1"
my5grantester    | time="2022-05-11T21:59:29Z" level=info msg="[GNB][UE] UE Mobility Restrict --Plmn-- Mcc: not informed Mnc: not informed"
my5grantester    | time="2022-05-11T21:59:29Z" level=info msg="[GNB][UE] UE Masked Imeisv: "
my5grantester    | time="2022-05-11T21:59:29Z" level=info msg="[GNB][UE] Allowed Nssai-- Sst: de Sd: 00007b"
my5grantester    | time="2022-05-11T21:59:29Z" level=info msg="[GNB][NAS][UE] Send Registration Accept."
my5grantester    | time="2022-05-11T21:59:29Z" level=info msg="[GNB][NGAP][AMF] Send Initial Context Setup Response."
my5grantester    | time="2022-05-11T21:59:29Z" level=info msg="[UE][NAS] Message with security header"
my5grantester    | time="2022-05-11T21:59:29Z" level=info msg="[UE][NAS] Message with integrity and ciphered"
my5grantester    | time="2022-05-11T21:59:29Z" level=info msg="[UE][NAS] successful NAS MAC verification"
my5grantester    | time="2022-05-11T21:59:29Z" level=info msg="[UE][NAS] successful NAS CIPHERING"
my5grantester    | time="2022-05-11T21:59:29Z" level=info msg="[UE][NAS] Receive Registration Accept"
my5grantester    | time="2022-05-11T21:59:29Z" level=info msg="[UE][NAS] UE 5G GUTI: [0 0 0 1]"
my5grantester    | time="2022-05-11T21:59:30Z" level=info msg="[GNB][SCTP] Receive message in 0 stream\n"
my5grantester    | time="2022-05-11T21:59:30Z" level=info msg="[GNB][NGAP] Receive PDU Session Resource Setup Request"
my5grantester    | time="2022-05-11T21:59:30Z" level=info msg="[GNB][NGAP][UE] PDU Session was created with successful."
my5grantester    | time="2022-05-11T21:59:30Z" level=info msg="[GNB][NGAP][UE] PDU Session Id: 1"
my5grantester    | time="2022-05-11T21:59:30Z" level=info msg="[GNB][NGAP][UE] NSSAI Selected --- sst: de sd: 00007b"
my5grantester    | time="2022-05-11T21:59:30Z" level=info msg="[GNB][NGAP][UE] PDU Session Type: ipv4"
my5grantester    | time="2022-05-11T21:59:30Z" level=info msg="[GNB][NGAP][UE] QOS Flow Identifier: 6"
my5grantester    | time="2022-05-11T21:59:30Z" level=info msg="[GNB][NGAP][UE] Uplink Teid: 231454274"
my5grantester    | time="2022-05-11T21:59:30Z" level=info msg="[GNB][NGAP][UE] Downlink Teid: 1"
my5grantester    | time="2022-05-11T21:59:30Z" level=info msg="[GNB][NGAP][UE] Non-Dynamic-5QI: 6"
my5grantester    | time="2022-05-11T21:59:30Z" level=info msg="[GNB][NGAP][UE] Priority Level ARP: 1"
my5grantester    | time="2022-05-11T21:59:30Z" level=info msg="[GNB][NGAP][UE] UPF Address: 192.168.72.202 :2152"
my5grantester    | time="2022-05-11T21:59:30Z" level=info msg="[UE][NAS] Message with security header"
my5grantester    | time="2022-05-11T21:59:30Z" level=info msg="[UE][NAS] Message with integrity and ciphered"
my5grantester    | time="2022-05-11T21:59:30Z" level=info msg="[UE][NAS] successful NAS MAC verification"
my5grantester    | time="2022-05-11T21:59:30Z" level=info msg="[UE][NAS] successful NAS CIPHERING"
my5grantester    | time="2022-05-11T21:59:30Z" level=info msg="[UE][NAS] Receive DL NAS Transport"
my5grantester    | time="2022-05-11T21:59:30Z" level=info msg="[UE][NAS] Receiving PDU Session Establishment Accept"
my5grantester    | time="2022-05-11T21:59:30Z" level=info msg="[UE][DATA] UE is ready for using data plane"
```

## Traffic test ##
UL Test ->
```shell
docker-compose-host $: docker exec -it my5grantester ping -c 3 -I uetun1 192.168.73.135
PING 192.168.73.135 (192.168.73.135) from 12.1.1.2 uetun1: 56(84) bytes of data.
64 bytes from 192.168.73.135: icmp_seq=1 ttl=63 time=5.35 ms
64 bytes from 192.168.73.135: icmp_seq=2 ttl=63 time=0.456 ms
64 bytes from 192.168.73.135: icmp_seq=3 ttl=63 time=0.595 ms

--- 192.168.73.135 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2016ms
rtt min/avg/max/mdev = 0.456/2.136/5.357/2.278 ms
```

DL Test ->
```shell
docker-compose-host $: docker exec -it oai-ext-dn ping -c 3 12.1.1.2
PING 12.1.1.2 (12.1.1.2) 56(84) bytes of data.
64 bytes from 12.1.1.2: icmp_seq=1 ttl=63 time=1.01 ms
64 bytes from 12.1.1.2: icmp_seq=2 ttl=63 time=0.531 ms
64 bytes from 12.1.1.2: icmp_seq=3 ttl=63 time=0.467 ms

--- 12.1.1.2 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2010ms
rtt min/avg/max/mdev = 0.467/0.670/1.013/0.244 ms
```
## Multiple UEs registration test ##
Load-test with UEs in queue*: 
* Update value in the [docker-compose-my5grantester-vpp.yaml](../docker-compose/docker-compose-my5grantester-vpp.yaml)
<!---
```shell
     NUM_UE: 10
```
-->
* Verify at AMF logs
```shell
docker-compose-host $: docker logs oai-amf
[2022-05-11T21:53:21.866098] [AMF] [amf_app] [info ] |----------------------------------------------------------------------------------------------------------------|
[2022-05-11T21:53:21.866102] [AMF] [amf_app] [info ] |----------------------------------------------------gNBs' information-------------------------------------------|
[2022-05-11T21:53:21.866105] [AMF] [amf_app] [info ] |    Index    |      Status      |       Global ID       |       gNB Name       |               PLMN             |
[2022-05-11T21:53:21.866110] [AMF] [amf_app] [info ] |      1      |    Connected     |         0x300       |         my5gRANTester        |            208, 95             | 
[2022-05-11T21:53:21.866113] [AMF] [amf_app] [info ] |----------------------------------------------------------------------------------------------------------------|
[2022-05-11T21:53:21.866115] [AMF] [amf_app] [info ] 
[2022-05-11T21:53:21.866117] [AMF] [amf_app] [info ] |----------------------------------------------------------------------------------------------------------------|
[2022-05-11T21:53:21.866120] [AMF] [amf_app] [info ] |----------------------------------------------------UEs' information--------------------------------------------|
[2022-05-11T21:53:21.866122] [AMF] [amf_app] [info ] | Index |      5GMM state      |      IMSI        |     GUTI      | RAN UE NGAP ID | AMF UE ID |  PLMN   |Cell ID|
[2022-05-11T21:53:21.866127] [AMF] [amf_app] [info ] |      1|       5GMM-REGISTERED|   208950000000043|               |               1|          1| 208, 95 |     16|
[2022-05-11T21:53:21.866131] [AMF] [amf_app] [info ] |      2|       5GMM-REGISTERED|   208950000000044|               |               2|          2| 208, 95 |     16|
[2022-05-11T21:53:21.866134] [AMF] [amf_app] [info ] |      3|       5GMM-REGISTERED|   208950000000045|               |               3|          3| 208, 95 |     16|
[2022-05-11T21:53:21.866138] [AMF] [amf_app] [info ] |      4|       5GMM-REGISTERED|   208950000000046|               |               4|          4| 208, 95 |     16|
[2022-05-11T21:53:21.866141] [AMF] [amf_app] [info ] |      5|       5GMM-REGISTERED|   208950000000047|               |               5|          5| 208, 95 |     16|
[2022-05-11T21:53:21.866144] [AMF] [amf_app] [info ] |      6|       5GMM-REGISTERED|   208950000000048|               |               6|          6| 208, 95 |     16|
[2022-05-11T21:53:21.866148] [AMF] [amf_app] [info ] |      7|       5GMM-REGISTERED|   208950000000049|               |               7|          7| 208, 95 |     16|
[2022-05-11T21:53:21.866151] [AMF] [amf_app] [info ] |      8|       5GMM-REGISTERED|   208950000000050|               |               8|          8| 208, 95 |     16|
[2022-05-11T21:53:21.866155] [AMF] [amf_app] [info ] |      9|       5GMM-REGISTERED|   208950000000051|               |               9|          9| 208, 95 |     16|
[2022-05-11T21:53:21.866158] [AMF] [amf_app] [info ] |     10|       5GMM-REGISTERED|   208950000000052|               |              10|         10| 208, 95 |     16|
[2022-05-11T21:53:21.866161] [AMF] [amf_app] [info ] |----------------------------------------------------------------------------------------------------------------|

```

## 8. Analysing the Scenario Results ##

| Pcap/log files                                                                             |
|:------------------------------------------------------------------------------------------ |
| [5gcn-deployment-my5G-RANTester.pcap](./results/My5g-RANTester/5gcn-deployment-my5grantester.pcap)                  |


* For detailed analysis of messages, please refer previous tutorial of [testing with dsTester](./docs/DEPLOY_SA5G_WITH_DS_TESTER.md).

## 9. Undeploy ##

Last thing is to remove all services - <br/>

* Undeploy the My5g-RANTester
```shell
docker-compose-host $: docker-compose -f docker-compose-my5grantester-vpp.yaml down
Stopping my5grantester ... done
Removing my5grantester ... done
Network demo-oai-public-net is external, skipping
Network oai-public-access is external, skipping
```

* Undeploy the core network
```shell
docker-compose-host $: docker-compose -f docker-compose-basic-vpp-nrf.yaml down
Stopping oai-smf    ... done
Stopping oai-amf    ... 
Stopping oai-ausf   ... 
Stopping oai-ext-dn ... 
Stopping oai-udm    ... 
Stopping vpp-upf    ... 
Stopping oai-udr    ... 
Stopping mysql      ... 
Stopping oai-nrf    ... 
```


