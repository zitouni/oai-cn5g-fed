#!/bin/bash
# Author Sagar Arora
# Contact sagar.arora@eurecom.fr
# Run this script from the place where all the charts are already present

DEFAULT_NAMESPACE=$(cat oai-amf/values.yaml | grep namespace | awk {'print $2'})

if [[ $1 == 'build' ]]; then
    if [[ -z $2 ]]; then
        NAMESPACE=$DEFAULT_NAMESPACE
        echo "creating new namespace $NAMESPACE"
        kubectl create ns $NAMESPACE
        echo "changing the namespace context so you can use kubectl get pods without supplying -n variable"
        kubectl config set-context --current --namespace=$NAMESPACE
    else
        NAMESPACE=$2
    fi
    sed -i "s/namespace: $DEFAULT_NAMESPACE/namespace: $NAMESPACE/g" oai-amf/values.yaml
    sed -i "s/namespace: $DEFAULT_NAMESPACE/namespace: $NAMESPACE /g" oai-smf/values.yaml
    sed -i "s/namespace: $DEFAULT_NAMESPACE/namespace: $NAMESPACE/g" oai-nrf/values.yaml
    sed -i "s/namespace: $DEFAULT_NAMESPACE/namespace: $NAMESPACE/g" oai-ausf/values.yaml
    sed -i "s/namespace: $DEFAULT_NAMESPACE/namespace: $NAMESPACE/g" oai-udm/values.yaml
    sed -i "s/namespace: $DEFAULT_NAMESPACE/namespace: $NAMESPACE/g" oai-udr/values.yaml
    sed -i "s/namespace: $DEFAULT_NAMESPACE/namespace: $NAMESPACE/g" oai-spgwu-tiny/values.yaml
    echo "Create a secret for pulling docker hub images you can use any account of docker hub because currently there is a limit when you pull images"
    echo "
kubectl create secret -n $NAMESPACE docker-registry regcred --docker-server=https://index.docker.io/v1/ --docker-username=<your-name> --docker-password=<your-pword> --docker-email=<your-email>
    "
elif [[ $1 == 'install' ]]; then
    if [[ -z $2 ]]; then
        NAMESPACE=$DEFAULT_NAMESPACE
    else 
        NAMESPACE=$2
    fi
    helm install mysql mysql/ -n $NAMESPACE
    sleep 20
    helm install udr oai-udr/ -n $NAMESPACE
    echo "sleeping for 20 seconds for udr to install"
    sleep 20
    helm install udm oai-udm/ -n $NAMESPACE
    echo "sleeping for 20 seconds for udm to install"
    sleep 20
    helm install ausf oai-ausf/ -n $NAMESPACE
    echo "sleeping for 20 seconds for ausf to install"
    sleep 20
    helm install nrf oai-nrf/ -n $NAMESPACE
    echo "sleeping for 20 seconds for nrf to install"
    sleep 20
    helm install amf oai-amf/ -n $NAMESPACE
    echo "sleeping for 20 seconds for amf to install"
    sleep 20
    helm install smf oai-smf/ -n $NAMESPACE
    echo "sleeping for 20 seconds for smf to install"
    sleep 20
    helm install spgwu oai-spgwu-tiny/ -n $NAMESPACE
    echo "sleeping for 20 seconds for spgwu to install"
    sleep 20
    kubectl get pods -n $NAMESPACE | grep oai
    echo "if you see all are in running state then you can start testing"
    SMF=$(kubectl get pods -n $NAMESPACE  | grep oai-smf | awk {'print $1'})
    SPGWU=$(kubectl get pods  -n $NAMESPACE  | grep oai-spgwu-tiny | awk {'print $1'})
    SPGWU_log1=$(kubectl logs -n $NAMESPACE $SPGWU spgwu | grep 'Received SX HEARTBEAT REQUEST')
    SPGWU_log2=$(kubectl logs -n $NAMESPACE $SPGWU spgwu | grep 'handle_receive(16 bytes)')
    if [[ -z $SPGWU_log ]] && [[ -z $SPGWU_log2 ]] ; then
            echo "SPGWU heartbeat problem,please check why the heartbeat is not working"
    fi
elif [[ $1 == 'uninstall' ]]; then
    if [[ -z $2 ]]; then
        NAMESPACE=$DEFAULT_NAMESPACE
    else 
        NAMESPACE=$2
    fi
    helm uninstall mysql -n $NAMESPACE
    sleep 5
    helm uninstall udr -n $NAMESPACE
    sleep 5
    helm uninstall udm -n $NAMESPACE
    sleep 5
    helm uninstall ausf -n $NAMESPACE
    sleep 5
    helm uninstall nrf -n $NAMESPACE
    sleep 5
    helm uninstall amf -n $NAMESPACE
    sleep 5
    helm uninstall smf -n $NAMESPACE
    sleep 5
    helm uninstall spgwu -n $NAMESPACE
    sleep 35
    echo "Everything should be terminating slowlly"
    kubectl get pods -n $NAMESPACE | grep oai
else
   echo "Author Sagar Arora Contact sagar.arora@eurecom.fr

1. First create environment using build command and then go to oai-amf/scripts/amf.conf to change the amf configuration according to your needs
2. Then change the configuration of smf and spgwu in oai-smf/scripts/smf.conf and oai-spgwu-tiny/scripts/spgw_u.conf respectively
3. Normally you don't have to change anything in ausf, udm and udr configuration but in case you want just check there configuration in values.yaml file present in there folder
4. Now build the environment using this script, if you don't provide a namespace then it will create one automatically oai5g
    ./helm_chart build <give_the_namespace_where_you_want_to_install> else it will do it oai5g namespace
5. Install the helm charts, if you don't provide a namespace then it will create one automatically oai5g
    ./helm_chart install <namespace>
    "
fi

