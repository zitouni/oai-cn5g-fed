#!/usr/bin/env bash

EBPF_GW_SETUP=${EBPF_GW_SETUP:-no}
EBPF_GW_MTU=${EBPF_GW_MTU:-1460}

if [[ ${EBPF_GW_SETUP} == "yes" ]];then
  echo -e "Trying to disable TCP checksum and to setup MTU on N6 interface"
  N6_IF_NAME=(`ifconfig | grep -B1 "inet $EBPF_GW_N6_IP_ADDR" | awk '$1!="inet" && $1!="--" {print $1}' | sed -e "s@:@@"`)
  echo -e "N6 interface is $N6_IF_NAME"
  ethtool -K $N6_IF_NAME tx off
  ifconfig $N6_IF_NAME mtu $EBPF_GW_MTU
  ifconfig $N6_IF_NAME
  echo -e "Adding UE IP routing to the N6 interface of UPF"
  ip route add $UE_IP_ADDRESS_POOL via $N6_UPF_IP_ADDR dev $N6_IF_NAME
  ip route
fi

echo "Done setting the configuration"
exec "$@"
