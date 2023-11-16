#!/usr/bin/env bash

UPF_FQDN=${UPF_FQDN:-oai-upf}
USE_FQDN=${USE_FQDN:-no}
UE_NETWORK=${UE_NETWORK:-12.1.1.0/24}

if [[ ${USE_FQDN} == "yes" ]];then
    echo -e "Trying to resolve UPF by FQDN : $UPF_FQDN"
    x=0
    while [ $x -le 50 ]
    do
        echo -e "Try number $x"
        getent hosts $UPF_FQDN > /dev/null
        ret=$?
        if [[ $ret -eq 0 ]]; then
            x=100
        else
            x=$((x + 1))
            sleep 5
        fi
    done
    if [[ $ret -ne 0 ]]; then
      echo -e "Could not resolve $UPF_FQDN"
      exit 2
    fi
    UPF_ADDR=(`getent hosts $UPF_FQDN | awk '{print $1}'`)
    echo -e "\nResolving UPF by FQDN : $UPF_FQDN - $UPF_ADDR"
    echo -e "ip route add $UE_NETWORK via $UPF_ADDR dev eth0"
    ip route add $UE_NETWORK via $UPF_ADDR dev eth0
fi

echo "Done setting the configuration"
exec "$@"
