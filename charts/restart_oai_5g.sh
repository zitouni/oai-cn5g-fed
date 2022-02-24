#!/bin/bash
# Author Sagar Arora
# Contact sagar.arora@eurecom.fr

AMF=$(kubectl get pods -n $NAMESPACE | grep oai-amf | awk {'print $1'})
NRF=$(kubectl get pods -n $NAMESPACE | grep oai-nrf | awk {'print $1'})
SMF=$(kubectl get pods -n $NAMESPACE | grep oai-smf | awk {'print $1'})
UDM=$(kubectl get pods -n $NAMESPACE | grep oai-udm | awk {'print $1'})
UDR=$(kubectl get pods -n $NAMESPACE | grep oai-udr | awk {'print $1'})
AUSF=$(kubectl get pods -n $NAMESPACE | grep oai-ausf | awk {'print $1'})
SPGWU=$(kubectl get pods -n $NAMESPACE | grep oai-spgwu-tiny | awk {'print $1'})

echo "Restarting udr"
kubectl delete pod $UDR
sleep 20
echo "Restarting udm"
kubectl delete pod $UDM
sleep 20
echo "Restarting ausf"
kubectl delete pod $AUSF
sleep 20
echo "Restarting NRF"
kubectl delete pod $NRF
sleep 20
echo "Restarting AMF"
kubectl delete pod $AMF
sleep 20
echo "Restarting SMF"
kubectl delete pod $SMF
sleep 20
echo "Restarting SPGWU"
kubectl delete pod $SPGWU
sleep 20

CHECK=$(kubectl get pods -n $NAMESPACE | grep 'Terminating')

kubectl get pods -n $NAMESPACE | grep oai

if [[ $CHECK ]]; then
	echo "Please wait till the time all the core network pods in $NAMESPACE are in running state, don't use them when in terminating state please"
fi

NEW_SPGWU=$(kubectl get pods -n $NAMESPACE | grep oai-spgwu-tiny | awk {'print $1'})

SPGWU_log1=$(kubectl logs -n $NAMESPACE $NEW_SPGWU spgwu | grep 'Received SX HEARTBEAT REQUEST')
SPGWU_log2=$(kubectl logs -n $NAMESPACE $NEW_SPGWU spgwu | grep 'handle_receive(16 bytes)')

if [[ -z $SPGWU_log ]] && [[ -z $SPGWU_log2 ]] ; then
        echo "SPGWU heartbeat problem"
fi
