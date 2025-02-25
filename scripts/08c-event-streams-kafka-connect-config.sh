#!/bin/sh
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
CP4I_VER='16.1.1' 
if [ -z "$CP4I_VER" ]; then echo "CP4I_VER not set, it must be provided on the command line."; exit 1; fi;
echo "CP4I_VER has been set to " $CP4I_VER
case "$CP4I_VER" in
   "2023.4" | "16.1.0" | "16.1.1" )
      ;;
   *)
      echo "This script is for CP4I v2023.4 or v16.1.0"
      exit 1
      ;;
esac
read -p "Press <Enter> to execute script..."
echo "Configuring Kafka Connect..."
###################
# INPUT VARIABLES #
###################
ES_INST_NAME='es-demo'
ES_NAMESPACE='tools'
################################
# INITIAL EVENT STREAMS CONFIG #
################################
case "$CP4I_VER" in
    "2022.4")
        ES_VERSION='11.1.6'
        ;;
    "2023.2")
        ES_VERSION='11.2.5'
        ;;
    "2023.4")
        ES_VERSION='11.3.2'
        ;;
    "16.1.0" | "16.1.1" )
        ES_VERSION='11.6.0'
        ;;
esac
echo "Getting Bootstrap information..."
#ES_BOOTSTRAP_SERVER=$(oc get eventstreams ${ES_INST_NAME} -n ${ES_NAMESPACE} -o=jsonpath='{range .status.kafkaListeners[*]}{.type} {.bootstrapServers}{"\n"}{end}' | awk '$1=="authsslsvc" {print $2}')
ES_BOOTSTRAP_SERVER=$(oc get eventstreams ${ES_INST_NAME} -n ${ES_NAMESPACE} -o=jsonpath='{range .status.kafkaListeners[*]}{.name} {.bootstrapServers}{"\n"}{end}' | awk '$1=="authsslsvc" {print $2}')
echo $ES_BOOTSTRAP_SERVER
echo "Updating template with Bootsrap info..."
( echo "cat <<EOF" ; cat templates/template-es-kafka-connect.yaml ;) | \
    CP4I_VER=${CP4I_VER} \
    ES_BOOTSTRAP_SERVER=${ES_BOOTSTRAP_SERVER} \
    ES_VERSION=${ES_VERSION} \
    sh > es-kafka-connect.yaml
echo "Creating Kafka Connect instance..."
oc apply -f es-kafka-connect.yaml
echo "Cleaning up temp files..."
rm -f es-kafka-connect.yaml
echo "Kafka Connect has been configured."
