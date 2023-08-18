#!/usr/bin/env bash

set -euo pipefail

UPF_HOST=${UPF_HOST:-oai-upf}
USE_FQDN=${USE_FQDN:-no}
UE_NETWORK=${UE_NETWORK:-12.1.1.0/24}

if [[ ${USE_FQDN} == "yes" ]];then
    UPF_ADDR=(`getent hosts oai-upf | awk '{print $1}'`)
    echo -e "\nResolving UPF by FQDN : $UPF_FQDN - $UPF_ADDR"
    ip route add $UE_NETWORK via $UPF_ADDR dev eth0
fi

echo "Done setting the configuration"
exec "$@"
