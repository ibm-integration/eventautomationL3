#!/bin/sh
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
###################
# INPUT VARIABLES #
###################
ES_INST_NAME='es-demo'
ES_NAMESPACE='tools'
echo "Configuring Kafka Connector DataGen..."
##################################
# KAFKA CONNECTOR DATAGEN CONFIG #
##################################
echo "Getting configuration information..."
ES_USER_PWD=$(oc get secret kafka-connect-user -n ${ES_NAMESPACE} -o jsonpath='{.data.password}' | base64 -d)
ES_CERT_PWD=$(oc get secret ${ES_INST_NAME}-cluster-ca-cert -n ${ES_NAMESPACE} -o=jsonpath='{.data.ca\.password}' | base64 -d)
#ES_SCHEMA_REGISTRY_URL=$(oc get eventstreams ${ES_INST_NAME} -n ${ES_NAMESPACE} -o=jsonpath='{range .status.endpoints[*]}{.name} {.uri}{"\n"}{end}' | awk '$1=="apicurioregistry" {print $2}')
ES_SCHEMA_REGISTRY_URL=$(oc get eventstreams ${ES_INST_NAME} -n ${ES_NAMESPACE} -o=jsonpath='{.status.endpoints[?(@.name=="apicurioregistry")].uri}')
echo "Updating template with config info..."
( echo "cat <<EOF" ; cat templates/template-es-kafka-connector-datagen.yaml ;) | \
    ES_USER_PWD=${ES_USER_PWD} \
    ES_CERT_PWD=${ES_CERT_PWD} \
    ES_SCHEMA_REGISTRY_URL=${ES_SCHEMA_REGISTRY_URL} \
    sh > es-kafka-connector-datagen.yaml
echo "Creating Kafka Connector DataGen instance..."
oc apply -f es-kafka-connector-datagen.yaml
echo "Cleaning up temp files..."
rm -f es-kafka-connector-datagen.yaml
echo "Kafka Connector DataGen has been configured."
