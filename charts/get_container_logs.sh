#!/bin/bash
# Author Sagar Arora
# Contact sagar.arora@eurecom.fr

NRF=$(kubectl get pods | grep oai-nrf | awk {'print $1'})
AMF=$(kubectl get pods | grep oai-amf | awk {'print $1'})
SMF=$(kubectl get pods | grep oai-smf | awk {'print $1'})
SPGWU=$(kubectl get pods | grep oai-spgwu-tiny | awk {'print $1'})
UDR=$(kubectl get pods | grep oai-udr | awk {'print $1'})
UDM=$(kubectl get pods | grep oai-udm | awk {'print $1'})
ASUF=$(kubectl get pods | grep oai-ausf | awk {'print $1'})

folder_name=logs_$(date +"%d-%m-%y-%H-%M-%S")

echo "creating a folder for storing logs, folder name:" logs/$folder_name
mkdir -p logs/$folder_name

echo "getting $NRF logs"
kubectl logs $NRF nrf &> logs/$folder_name/nrf.logs
echo "getting $AMF logs"
kubectl logs $AMF amf &> logs/$folder_name/amf2.logs
echo "getting $SMF logs"
kubectl logs $SMF smf &> logs/$folder_name/smf.logs
echo "getting $SPGWU logs"
kubectl logs $SPGWU spgwu &> logs/$folder_name/spgwu.logs
echo "getting $UDR logs"
kubectl logs $UDR udr &> logs/$folder_name/udr.logs
echo "getting $UDM logs"
kubectl logs $UDM udm &> logs/$folder_name/udm.logs
echo "getting $AUSF logs"
kubectl logs $AUSF ausf &> logs/$folder_name/ausf.logs

echo "Creating a tar file for developers"
tar -cf logs/$folder_name.tar logs/$folder_name/
rm -rf logs/$folder_name/
