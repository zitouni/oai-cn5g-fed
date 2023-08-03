<table style="border-collapse: collapse; border: none;">
  <tr style="border-collapse: collapse; border: none;">
    <td style="border-collapse: collapse; border: none;">
      <a href="http://www.openairinterface.org/">
         <img src="./images/oai_final_logo.png" alt="" border=3 height=50 width=150>
         </img>
      </a>
    </td>
    <td style="border-collapse: collapse; border: none; vertical-align: center;">
      <b><font size = "5">OpenAirInterface 5G Core Network Configuration </font></b>
    </td>
  </tr>
</table>

**TABLE OF CONTENTS**

1. [Basics](#1-basics)
2. [Description of configuration](#2-description-of-configuration)
3. [Database configuration](#3-database-configuration)

# 1. Basics

All the OAI NFs are configured using a `YAML` configuration file. This document describes the structure, the allowed
values and the default values.

## Location of the configuration file

When you are using the [docker-compose deployment](DEPLOY_SA5G_BASIC_DEPLOYMENT.md), the configuration file is located
inside the container:

```
/openair-<nf-name>/etc/config.yaml
```

Each of the NF repositories has an example documentation, which is also copied in the Docker image during build:

| Network Function | Repository                  | Location                                                                                          | 
|:-----------------|:----------------------------|:--------------------------------------------------------------------------------------------------|
| AMF              | (Gitlab) cn5g/oai-cn5g-amf  | [etc/config.yaml](https://gitlab.eurecom.fr/oai/cn5g/oai-cn5g-amf/-/blob/master/etc/config.yaml)  |
| AUSF             | (Gitlab) cn5g/oai-cn5g-ausf | [etc/config.yaml](https://gitlab.eurecom.fr/oai/cn5g/oai-cn5g-ausf/-/blob/master/etc/config.yaml) |
| NRF              | (Gitlab) cn5g/oai-cn5g-nrf  | [etc/config.yaml](https://gitlab.eurecom.fr/oai/cn5g/oai-cn5g-nrf/-/blob/master/etc/config.yaml)  |
| NSSF             | (Gitlab) cn5g/oai-cn5g-nssf | [etc/config.yaml](https://gitlab.eurecom.fr/oai/cn5g/oai-cn5g-nssf/-/blob/master/etc/config.yaml) |
| PCF              | (Gitlab) cn5g/oai-cn5g-pcf  | [etc/config.yaml](https://gitlab.eurecom.fr/oai/cn5g/oai-cn5g-pcf/-/blob/master/etc/config.yaml)  |
| SMF              | (Gitlab) cn5g/oai-cn5g-smf  | [etc/config.yaml](https://gitlab.eurecom.fr/oai/cn5g/oai-cn5g-smf/-/blob/master/etc/config.yaml)  |
| UDM              | (Gitlab) cn5g/oai-cn5g-udm  | [etc/config.yaml](https://gitlab.eurecom.fr/oai/cn5g/oai-cn5g-udm/-/blob/master/etc/config.yaml)  |
| UDR              | (Gitlab) cn5g/oai-cn5g-udr  | [etc/config.yaml](https://gitlab.eurecom.fr/oai/cn5g/oai-cn5g-udr/-/blob/master/etc/config.yaml)  |
| UPF              | (Gitlab) cn5g/oai-cn5g-upf  | [etc/config.yaml](https://gitlab.eurecom.fr/oai/cn5g/oai-cn5g-upf/-/blob/master/etc/config.yaml)  |

When you are using a bare-metal deployment, you have to tell the NF which file to load, for example for SMF:

```
./smf -c /your/path/to/config.yaml -o
```

## Example configurations

The [docker-compose](../docker-compose) folder contains example configurations, which are used by the tutorials
described in [docs](./).

You can have a look at the [docker-compose/conf](../docker-compose/conf) folder to see real-world examples of how the
OAI 5GC NFs can be configured.

## Validation

Each configuration is validated during startup of the NF. In case of a wrong configuration, an error is printed and the
NF does not start.
Therefore, please make sure that all the Docker containers started successfully.

# 2. Description of Configuration

The configuration is designed in a way so that you can have one `config.yaml` file to configure all your NFs.
The file has different sections and some of these sections are not relevant for all NFs. Each section is described in
the following chapters.
The following table gives an overview:

| Name           | Description                   | Relevant NFs |
|:---------------|:------------------------------|:-------------|
| `log_lvl`      | [Log Level](#log-level)       | All          |
| `register_nf`  | [Register NF](#register-nf)   | All          |
| `http_version` | [HTTP Version](#http-version) | All          |
| `nfs`          | [NFs](#nfs)                   | All          |
| `database`     | [Database](#database)         | AMF, UDR     |
| `dnns`         | [DNNs](#dnns)                 | SMF, UPF     |
| `amf`          | [AMF](#amf)                   | AMF          |
| `smf`          | [SMF](#smf)                   | SMF          |
| `pcf`          | [PCF](#pcf)                   | PCF          |
| `nssf`         | [NSSF](#nssf)                 | NSSF         |

The default values described in this document are the values that are taken by the NF if you do not specify it in the
configuration file. If there is no default value here, you need to configure it.

## Log Level

The `log_level` key configures the log level of the NF.
It is a dictionary that can contain the following keys:

* `general`
* `ausf`
* `amf`
* `nrf`
* `nssf`
* `pcf`
* `smf`
* `udm`
* `udr`
* `upf`

Each key can take the following values:

| Name      | Type   | Description       | Allowed values                         | Default value |
|:----------|:-------|:------------------|:---------------------------------------|:--------------|
| Log Level | String | Set the log level | `debug`, `info`, `warn`, `error` `off` | `info`        |

Here, you can configure different log levels for different NFs. Each NF reads its value, e.g. the SMF reads the `smf`
key.
When you configure `general`, it is the basic configuration for all NFs. Thus, if you want to enable debug level for
SMF, but
want to have info log level for all other NFs, you can have the following configuration:

```yaml
log_level:
  general: info
  smf: debug
```

## Register NF

The `register_nf` key follows the same principles as the [Log Level](#log-level). Here, you can configure
if an NF should register to NRF. It is important to note that if one NF registers to NRF, it *expects* other NFs to
register
towards NRF. This means that a register NF will use the NRF discovery or event notification mechanism.

| Name        | Type | Description                                               | Allowed values                              | Default value |
|:------------|:-----|:----------------------------------------------------------|:--------------------------------------------|:--------------|
| Register NF | Bool | Set yes to register to NRF and use NF discovery mechanism | `yes`, `no` (and other YAML boolean values) | `no`          | 

## HTTP Version

Here, you can configure which HTTP version should be used for the client and the server. The NF will only launch one
HTTP server, serving either HTTP version 1 or version 2.
Currently, there is no difference between `1` and `1.1` as all our servers use HTTP version `1.1`.

| Name         | Type | Description                               | Allowed values  | Default value |
|:-------------|:-----|:------------------------------------------|:----------------|:--------------|
| HTTP Version | Int  | Set the HTTP version of client and server | `1`, `1.1`, `2` | `1`           |

## NFs

The `nfs` section allows you to configure SBI and other interfaces for each NF.

It is a dictionary that can contain the following keys:

* `ausf`
* `amf`
* `nrf`
* `nssf`
* `pcf`
* `smf`
* `udm`
* `udr`
* `upf`

Each key defines an interface configuration that looks as follows:

```yaml
host: <hostname>
sbi:
  port: <port>
  api_version: <api_version>
  interface_name: <interface_name>
```

The allowed values are described in the following table:

| Name           | Type   | Description                            | Allowed values                                                   | Default value |
|:---------------|:-------|:---------------------------------------|:-----------------------------------------------------------------|:--------------|
| Host           | String | Hostname or IP of the NF               | Any hostname or an IPv4 address in dotted decimal representation | Depends on NF |
| Port           | Int    | Port of the SBI interface              | Any integer between `1` and `65535`                              | `80`          |
| API Version    | String | API version used for SBI communication | `v1`, `v2`                                                       | `v1`          |
| Interface name | String | Host interface to serve HTTP server    | Any string                                                       | `eth0`        |

The interface name is only relevant for the local NF, e.g., SMF only takes the interface name from the `smf` key.
If the interface cannot be read or does not exist, the NF will terminate.

The `host` value is different for each NF key. Also, not all the keys are read by all NFs. The following table describes
this:

| Key    | Host default value | Read by NFs   |
|:-------|:-------------------|:--------------|
| `ausf` | `oai-ausf`         | AUSF, AMF     |
| `amf`  | `oai-amf`          | AMF, SMF      |
| `nrf`  | `oai-nrf`          | All NFs       |
| `nssf` | `oai-nssf`         | NSSF, AMF     |
| `pcf`  | `oai-pcf`          | PCF, SMF      |
| `smf`  | `oai-smf`          | SMF, AMF      |
| `udm`  | `oai-udm`          | UDM, AMF, SMF |
| `udr`  | `oai-udr`          | UDR, UDM      |
| `upf`  | `oai-upf`          | UPF           | 

The NF will only parse and validate the NF key if necessary. For example, if [register NF](#register-nf) is set, it only
takes the values it needs.

### AMF specific NF configuration

AMF has an SBI interface and also a N2 interface. The `amf` key can be configured as follows:

```yaml
host: <hostname>
sbi:
  port: <port>
  api_version: <api_version>
  interface_name: <interface_name>
n2:
  port: <port>
  interface_name: <interface_name>
```

The description of the N2 interface is as follows:

| Name           | Type   | Description                       | Allowed values                      | Default value |
|:---------------|:-------|:----------------------------------|:------------------------------------|:--------------|
| Port           | Int    | Port of the N2 interface          | Any integer between `1` and `65535` | `38412`       |
| Interface name | String | Host interface to serve N2 server | Any string                          | `eth0`        |

### SMF specific NF configuration

Similar to the AMF, the SMF also configures an N4 interface. The `smf` key can be configured as follows:

```yaml
host: <hostname>
sbi:
  port: <port>
  api_version: <api_version>
  interface_name: <interface_name>
n2:
  port: <port>
  interface_name: <interface_name>
```

The description of the N4 interface is as follows:

| Name           | Type   | Description                       | Allowed values                      | Default value |
|:---------------|:-------|:----------------------------------|:------------------------------------|:--------------|
| Port           | Int    | Port of the N4 interface          | Any integer between `1` and `65535` | `8805`        |
| Interface name | String | Host interface to serve N4 server | Any string                          | `eth0`        |

### UPF specific NF configuration

The UPF serves more interfaces. The `upf` key can be configured as follows:

```yaml
host: <hostname>
sbi:
  port: <port>
  api_version: <api_version>
  interface_name: <interface_name>
n3:
  interface_name: <n3_interface_name>
  port: <n3_port>
n4:
  interface_name: <n4_interface_name>
  port: <n4_port>
n6:
  interface_name: <n6_interface_name>
``` 

The description of the N3, N4 and N6 interfaces of UPF are as follows:

| Name              | Type   | Description                                  | Allowed values                      | Default value |
|:------------------|:-------|:---------------------------------------------|:------------------------------------|:--------------|
| N3 Port           | Int    | Port of the N3 GTP-u interface               | Any integer between `1` and `65535` | `2152`        |
| N3 Interface Name | String | Host interface to receive GTP packets        | Any string                          | `eth0`        |
| N4 Port           | Int    | Port of the N4 interface                     | Any integer between `1` and `65535` | `8805`        |
| N4 Interface Name | String | Host interface to serve N4 server            | Any string                          | `eth0`        |
| N6 Interface Name | String | Host interface to receive IP traffic from DN | Any string                          | `eth0`        |

## Database

The `database` section allows you to configure how to connect to the database.

It takes the following keys:

```yaml
database:
  host: <db_host>
  user: <db_user>
  type: <db_type>
  password: <db_pw>
  database_name: <db_name>
  generate_random: <generate_random>
  connection_timeout: <timeout>
```

The allowed values are described in the following table:

| Name            | Type   | Description                                         | Allowed values                              | Default value |
|:----------------|:-------|:----------------------------------------------------|:--------------------------------------------|:--------------|
| DB Host         | String | Host of the database to connect                     | Any string                                  |               |
| DB User         | String | User to authenticate to the database                | Any string                                  |               |
| DB Type         | String | Type of the database (e.g. `mysql`)                 | Any string                                  |               |
| DB Password     | String | Password to authenticate to the database            | Any string                                  |               |
| DB Name         | String | Name of the database to use                         | Any string                                  |               |
| Generate Random | Bool   | ?????????? TODO ??                                  | `yes`, `no` (and other YAML boolean values) | `no`          |
| Timeout         | Int    | ?? TODO (I suspect the timeout for DB connections?) | Any integer                                 |               |

## DNNs

In the `dnns` section you can configure DNNs, which are used by SMF and UPF.
It is a list of DNN configuration. Each DNN configuration can can configure the following values:

```yaml
dnn: <dnn_name>
pdu_session_type: <pdu_type>
ipv4_subnet: <ipv4_subnet>
ipv6_prefix: <ipv6_prefix>
ue_dns:
  primary_ipv4: <primary_dns_v4>
  primary_ipv6: <primary_dns_v6>
  secondary_ipv4: <secondary_dns_v4>
  secondary_ipv6: <secondary_dns_v6>
```

The `ue_dns` key is only used by SMF and there is no default value. If you do not provide anything here, the `ue_dns`
configuration from SMF is used. It is used to configure different DNS servers per DNN.

The allowed values are described in the following table:

| Name             | Type   | Description                                                            | Allowed values                                                        | Default value |
|:-----------------|:-------|:-----------------------------------------------------------------------|:----------------------------------------------------------------------|:--------------|
| DNN              | String | DNN to be used by SMF, UPF and communicated by the UE                  | Any string                                                            | `default`     |
| PDU Session Type | String | Type of the PDU session ( *currently only IPV4 supported by SMF* )     | `IPV4`, `IPV4V6`, `IPV6`                                              | `IPV4`        |
| IPv4 Subnet      | String | IPv4 subnet which is used to assign UE IPv4 addresses for PDU sessions | IP address in CIDR format: Host in dotted decimal followed by /suffix | `12.1.1.0/24` |
| IPv6 Prefix      | String | IPv6 prefix which is used to assign UE IPv6 addresses for PDU sessions | Any value                                                             |               | 

If you do not configure any DNN in the `dnns` section, or you remove the `dnns` section completely, the following
default dnn is configured:

```yaml
dnn: default
pdu_session_type: IPV4
ipv4_subnet: 12.1.1.0/24
```

Otherwise, your configuration takes precedence and the default DNN is removed.

## AMF

The `amf` section is used to configure the behavior of AMF.

You can configure the following values:

```yaml
amf:
  pid_directory: <pid_directory>
  amf_name: <amf_name>
  support_features_options:
    enable_simple_scenario: <enable_simple_scenario>
    enable_nssf: <enable_nssf>
    enable_smf_selection: <enable_smf_selection>
    use_external_udm: <use_external_udm>
  relative_capacity: <relative_capacity>
  statistics_timer_interval: <statistics_timer_interval>
  emergency_support: <emergency_support>
  # In this list, you can configure several served GUAMIs
  served_guami_list:
    - mcc: <guami_mcc>
      mnc: <guami_mnc>
      amf_region_id: <amf_region_id>
      amf_set_id: <amf_set_id>
      amf_pointer: <amf_pointer>
  # In this list, you can configure several supported PLMNs
  plmn_support_list:
    - mcc: <plmn_mcc>
      mnc: <plmn_mnc>
      tac: <tac>
      # In this list, you can configure several NSSAIs per PLMN
      nssai:
        - sst: <sst>
          sd: <sd>
  # In this list, you can configure all the supported integrity algorithms
  supported_integrity_algorithms:
    - <int_algorithm>
  # In this list, you can configure all the supported encryption algorithms
  supported_encryption_algorithms:
    - <enc_algorithm>
```

The allowed values and the description of the configuration of AMF are described in the following table:

| Name                      | Type   | Description                                                                        | Allowed values                              | Default value |
|:--------------------------|:-------|:-----------------------------------------------------------------------------------|:--------------------------------------------|:--------------|
| PID Directory             | String | TODO currenly unused???                                                            | Any string                                  |               |
| AMF Name                  | String | AMF Name used in AMF NF profile                                                    | Any string                                  |               |
| Enable Simple Scenario    | Bool   | If set to yes, AMF will not use AUSF/UDM/UDR, but connect to MySQL database itself | `yes`, `no` (and other YAML boolean values) | `no`          |
| Enable NSSF               | Bool   | If set to yes, AMF will use NSSF                                                   | `yes`, `no` (and other YAML boolean values) | `no`          |
| Enable SMF Selection      | Bool   | If set to yes, AMF will use NRF discovery mechanism to select SMF                  | `yes`, `no` (and other YAML boolean values) | `no`          |
| Relative Capacity         | Int    | Relative capacity communicated over NGAP to gNB (TODO verify)                      | Any int                                     | `0`           |
| Statistics Timer Interval | Int    | Interval for logging AMF statistics                                                | Any int                                     | `0`           |
| Emergency Support         | Bool   | Indicate towards UE if emergency registration is supported                         | `yes`, `no` (and other YAML boolean values) | `no`          |
| GUAMI MCC                 | String | MCC Part of Globally Unique AMF ID (GUAMI)                                         | Any string                                  | `001`         |
| GUAMI MNC                 | String | MNC Part of GUAMI                                                                  | Any string                                  | `01`          |
| AMF Region ID             | Int    | AMF Region ID of GUAMI                                                             | Any int                                     | `0`           |
| AMF Set ID                | Int    | AMF Set ID of GUAMI                                                                | Any int                                     | `0`           |
| AMF Pointer               | Int    | AMF Pointer of GUAMI                                                               | Any int                                     | `0`           |
| PLMN MCC                  | String | MCC of supported PLMN                                                              | Any string                                  | `001`         |
| PLMN MNC                  | String | MNC of supported PLMN                                                              | Any string                                  | `01`          |
| TAC                       | Int    | TAC of supported PLMN                                                              | Any int                                     | `1`           |
| SST                       | Int    | SST of SNSSAI                                                                      | Any int                                     | `1`           |
| SD                        | String | SD of SNSSAI                                                                       | Any string                                  | `0xFFFFFF`    |
| Integrity Algorithm       | String | Supported integrity algorithm, used for security mode command messages             | Any string                                  |               |
| Encryption Algorithm      | String | Supported encryption algorithm, used for security mode command messages            | Any string                                  |               |

When configuring AMF, you have to be careful to configure the GUAMI, PLMN and NSSAIs correctly. Upon UE registration,
the requested PLMN and NSSAI of the UE is verified. In case it is not configured by AMF, AMF will reply with a
registration reject message.
Thus, you have to properly configure these values according to gNB and UE. The same is true for the TAC.

If you do not configure any integrity algorithms, AMF will take the following default configuration:

```yaml
supported_integrity_algorithms:
  - "NIA0"
  - "NIA1"
  - "NIA2"
```

If you do not configure any encryption algorithm, AMF will take the following default configuration:

```yaml
supported_encryption_algorithms:
  - "NEA0"
  - "NEA1"
  - "NEA2"
```

## SMF

The `smf` section is used to configure the behavior of the SMF.

You can configure the following values:

```yaml
ue_mtu: <ue_mtu>
support_features:
  use_local_subscription_info: <use_local_subscription_info>
  use_local_pcc_rules: <use_local_pcc_rules>
upfs:
  - host: <upf_host>
    port: <upf_port>
    config:
      enable_usage_reporting: <enable_usage_reporting>
      enable_dl_pdr_in_pfcp_session_establishment: <enable_dl_pdr_in_pfcp_session_establishment>
      n3_local_ipv4: <n3_local_ipv4>
    upf_info:
      interfaceUpfInfoList:
        - interfaceType: <interface_type>
          networkInstance: <network_instance>
ue_dns:
  primary_ipv4: <primary_dns_v4>
  primary_ipv6: <primary_dns_v6>
  secondary_ipv4: <secondary_dns_v4>
  secondary_ipv6: <secondary_dns_v6>
ims:
  pcscf_ipv4: <pcscf_ipv4>
  pcscf_ipv6: <pcscf_ipv6>
local_subscription_infos:
  - single_nssai:
      sst: <sst>
      sd: <sd>
    dnn: <dnn>
    ssc_mode: <ssc_mode>
    qos_profile:
      5qi: <5qi>
      priority: <priority>
      arp_priority: <arp_priority>
      arp_preempt_capability: <arp_preempt_capability>
      arp_preempt_vulnerability: <arp_preempt_vulnerability>
      session_ambr_ul: <session_ambr_ul>
      session_ambr_dl: <session_ambr_dl>
```

The allowed values and the description of the configuration of AMF are described in the following table:

| Name                                        | Type   | Description                                                                                                                                                                                                    | Allowed values                                                   | Default value                      |
|:--------------------------------------------|:-------|:---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|:-----------------------------------------------------------------|:-----------------------------------|
| UE MTU                                      | Int    | UE MTU, signaled to the UE via PCO                                                                                                                                                                             | Any int                                                          | `1500`                             |
| Use Local Subscription Info                 | Bool   | If set to yes, SMF will use the information from `local_subscription_infos`, otherwise UDM is contacted. In this case, you have to provide `udm` in [NFs](#nfs)                                                | `yes`, `no` (and other YAML boolean values)                      | `no`                               |
| Use Local PCC rules                         | Bool   | If set to no, SMF will get PCC rules from PCF. *Local PCC Rules on SMF are not supported yet*. In this case, you have to provide `pcf` in [NFs](#nfs)                                                          | `yes`, `no` (and other YAML boolean values)                      | `yes`                              |
| UPF Host                                    | String | Host of the UPF                                                                                                                                                                                                | Any hostname or an IPv4 address in dotted decimal representation |                                    |
| UPF Port                                    | Int    | Port of the UPF N4 interface                                                                                                                                                                                   | Any integer between `1` and `65535`                              | `8805`                             |
| Enable Usage Reporting                      | Bool   | If set to yes, SMF will request UPF to send usage reports                                                                                                                                                      | `yes`, `no` (and other YAML boolean values)                      | `no`                               |
| Enable DL PDR in PFCP Session Establishment | Bool   | If set to yes, SMF will send DL rules during PFCP session establishment and update these rules with the gNB T-EID in a session modification. Enable this if your UPF expects this behavior                     | `yes`, `no` (and other YAML boolean values)                      | `no`                               |
| Local N3 IPv4                               | String | If the UPF is not Release 16-compliant and does not support generating F-TEIDs, SMF will generate the F-TEID and use this IP address for the F-TEID.                                                           | IPv4 address in dotted decimal representation                    |                                    |
| UPF Info                                    | Struct | This datatype is used to configure the UPF profile on SMF, especially useful when no NRF is used. It follows the `UpfInfo` definition of 3GPP TS 29.510, but only `interfaceUpfInfoList` is supported for now. | `UpfInfo` from 29.510                                            |                                    |
| Interface Type                              | String | Interface type of this interface                                                                                                                                                                               | Any string                                                       | `N3` or `N6`                       |
| Network Instance                            | String | Network Instance of this interface                                                                                                                                                                             | Any string                                                       | `access.oai.org` or `core.oai.org` |
| Primary DNS IPv4                            | String | Primary DNS IPv4, signaled to the UE via PCO                                                                                                                                                                   | IPv4 address in dotted decimal representation                    | `8.8.8.8`                          |
| Primary DNS IPv6                            | String | Primary DNS IPv6, signaled to the UE via PCO                                                                                                                                                                   | Any string                                                       |                                    |
| Secondary DNS IPv4                          | String | Secondary DNS IPv4, signaled to the UE via PCO                                                                                                                                                                 | IPv4 address in dotted decimal representation                    | `1.1.1.1`                          |
| Secondary DNS IPv6                          | String | Secondary DNS IPv6, signaled to the UE via PCO                                                                                                                                                                 | Any string                                                       |                                    |
| P-CSCF IPv4                                 | String | IPv4 address of P-CSCF for IMS, signaled to the UE via PCO                                                                                                                                                     | IPv4 address in dotted decimal representation                    | `127.0.0.1`                        |
| P-CSCF IPv6                                 | String | IPv6 address of P-CSCF for IMS, signaled to the UE via PCO                                                                                                                                                     | Any string                                                       |                                    |
| SST                                         | Int    | SST of SNSSAI                                                                                                                                                                                                  | Any integer between `0` and `255`                                | `1`                                |
| SD                                          | Int    | SD of SNSSAI, supports hex (`0x123123`) or decimal representation.                                                                                                                                             | Any integer between `0` and `16777215` (`0xFFFFFF`)              | `0xFFFFFF`                         |
| DNN                                         | String | DNN to be used for this slice subscription. The DNN should match the `dnn` of a configured DNN in [DNNs](#dnns)                                                                                                | Any string                                                       | `default`                          |
| SSC Mode                                    | Int    | Session and Service Continuity Mode                                                                                                                                                                            | Any integer between `1` and `3`                                  | `1`                                |
| 5QI                                         | Int    | 5QI of QoS profile                                                                                                                                                                                             | Any integer between `1` and `254`                                | `9`                                |
| Priority                                    | Int    | Priority of QoS profile                                                                                                                                                                                        | Any integer between `1` and `127`                                | `1`                                |
| ARP Priority                                | Int    | Priority of ARP                                                                                                                                                                                                | Any integer between `1` and `15`                                 | `1`                                |
| ARP Preempt Capability                      | String | Preemption capability of ARP                                                                                                                                                                                   | Any string                                                       | `NOT_PREEMPT`                      |
| ARP Preempt Vulnerability                   | String | Preemption vulnerability of ARP                                                                                                                                                                                | Any string                                                       | `NOT_PREEMPTABLE`                  |
| Session AMBR UL                             | String | Session AMBR for uplink                                                                                                                                                                                        | Any string                                                       | `1000Mbps`                         |
| Session AMBR DL                             | String | Session AMBR for downlink                                                                                                                                                                                      | Any string                                                       | `1000Mbps`                         |

The UPF Info on SMF is currently very basic and supports only configuring the interface type and the network instance.
If you omit this configuration, SMF adds the following default configuration:

```yaml
interfaceUpfInfoList:
  - interfaceType: N3
    networkInstance: access.oai.org
  - interfaceType: N6
    networkInstance: core.oai.org
```

If you do not configure `local_subscription_infos`, SMF will use one default subscription info configuration:

```yaml
single_nssai:
  sst: 1
  sd: 0xFFFFFF
dnn: "default"
ssc_mode: 1
qos_profile:
  5qi: 9
  priority: 1
  arp_priority: 1
  arp_preempt_capability: "NOT_PREEMPT"
  arp_preempt_vulnerability: "NOT_PREEMPTABLE"
  session_ambr_ul: "1000Mbps"
  session_ambr_dl: "1000Mbps"
```

*Note: In case you use a COTS UE, it is highly recommended to configure an `ims` DNN. Please see the examples on how to
do that.*

## PCF

You can configure the directory where PCF policy configuration is stored:

```yaml
local_policy:
  policy_decisions_path: <policy_decisions_path>
  pcc_rules_path: <pcc_rules_path>
  traffic_rules_path: <traffic_rules_path>
```

How to configure the policies for PCF itself are not covered in this document. You can see
the [policies](../docker-compose/policies) folder for examples.

The allowed values of the PCF configuration are as follows:

| Name                  | Type   | Description                            | Allowed values | Default value                            |
|:----------------------|:-------|:---------------------------------------|:---------------|:-----------------------------------------|
| Policy Decisions Path | String | Path to the policy decisions directory | Any string     | `/openair-pcf/policies/policy_decisions` |
| PCC Rules Path        | String | Path to the PCC rules directory        | Any string     | `/openair-pcf/policies/traffic_rules`    |
| Traffic Rules Path    | String | Path to the traffic rules directory    | Any string     | `/openair-pcf/policies/pcc_rules`        |

The paths you configure here are not validated upon reading the configuration, but PCF will try to open these
directories on start and inform you if there was an issue.

## NSSF

You can configure the directory where NSSF slicing configuration is stored:

```yaml
slice_config_path: <slice_config_path> 
```

How to configure the slice configuration for NSSF itself is not covered in this document. You can see
the [nssf_slice_config.yaml](../docker-compose/conf/nssf_slice_config.yaml) file for an example.

The allowed values of the NSSF configuration are as follows:

| Name              | Type   | Description                     | Allowed values | Default value                              |
|:------------------|:-------|:--------------------------------|:---------------|:-------------------------------------------|
| Slice Config Path | String | Path to the slice configuration | Any string     | `/openair-nssf/etc/nssf_slice_config.yaml` |

The path you configure here is not validated upon reading the configuration, but NSSF will try to open this file on
start and inform you when there is an issue.

# 3. Database configuration

A new user subscription information should be present in the mysql database before trying to connect the UE. This can
be done by adding the UE information in the [oai_db2.sql](../docker-compose/database/oai_db2.sql) file

First, you have to configure the authentication subscription:

```sql
INSERT INTO `AuthenticationSubscription` (`ueid`, `authenticationMethod`, `encPermanentKey`, `protectionParameterId`,
                                          `sequenceNumber`, `authenticationManagementField`, `algorithmId`, `encOpcKey`,
                                          `encTopcKey`, `vectorGenerationInHss`, `n5gcAuthMethod`,
                                          `rgAuthenticationInd`, `supi`)
VALUES ('208950000000031', '5G_AKA', '0C0A34601D4F07677303652C0462535B', '0C0A34601D4F07677303652C0462535B',
        '{\"sqn\": \"000000000020\", \"sqnScheme\": \"NON_TIME_BASED\", \"lastIndexes\": {\"ausf\": 0}}', '8000',
        'milenage', '63bfa50ee6523365ff14c1f45f88737d', NULL, NULL, NULL, NULL, '208950000000031');
```

If you configure `use_local_subscription_info: no` in SMF, you also have to add the subscription info for your UE in the
database:

```sql
INSERT INTO `SessionManagementSubscriptionData` (`ueid`, `servingPlmnid`, `singleNssai`, `dnnConfigurations`)
VALUES ('208950000000031', '20895', '{\"sst\": 222, \"sd\": \"123\"}',
        '{\"default\":{\"pduSessionTypes\":{ \"defaultSessionType\": \"IPV4\"},\"sscModes\": {\"defaultSscMode\": \"SSC_MODE_1\"},\"5gQosProfile\": {\"5qi\": 6,\"arp\":{\"priorityLevel\": 1,\"preemptCap\": \"NOT_PREEMPT\",\"preemptVuln\":\"NOT_PREEMPTABLE\"},\"priorityLevel\":1},\"sessionAmbr\":{\"uplink\":\"100Mbps\", \"downlink\":\"100Mbps\"}}}');
```

The `dnnConfigurations` column has to be defined in JSON and follows the `dnnConfiguration` type from 3GPP TS 29.503.
Therefore, here you can configure your QoS profile and DNN configuration accordingly for this UE.

If, for example, you want to configure a static IP address for a UE, you can define the following:

```sql
INSERT INTO `SessionManagementSubscriptionData` (`ueid`, `servingPlmnid`, `singleNssai`, `dnnConfigurations`)
VALUES ('208950000000031', '20895', '{\"sst\": 222, \"sd\": \"123\"}',
        '{\"default\":{\"pduSessionTypes\":{ \"defaultSessionType\": \"IPV4\"},\"sscModes\": {\"defaultSscMode\": \"SSC_MODE_1\"},\"5gQosProfile\": {\"5qi\": 6,\"arp\":{\"priorityLevel\": 1,\"preemptCap\": \"NOT_PREEMPT\",\"preemptVuln\":\"NOT_PREEMPTABLE\"},\"priorityLevel\":1},\"sessionAmbr\":{\"uplink\":\"100Mbps\", \"downlink\":\"100Mbps\"},\"staticIpAddress\":[{\"ipv4Addr\": \"12.1.1.4\"}]}}');
```
