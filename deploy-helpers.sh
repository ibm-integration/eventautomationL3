!/bin/bash
# © Copyright IBM Corporation 2023, 2024
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

function line_separator () {
  echo "####################### $1 #######################"
}

NAMESPACE=${1:-"tools"}
BLOCK_STORAGE=${2:-"ocs-storagecluster-ceph-rbd"}
INSTALL_CP4I=${5:-true}
MQ_TEMPLATE=${3:-"orders.yaml_template"}
ENABLE_CONNECTOR=${4:-false}
FILE_STORAGE=${5:-"ocs-storagecluster-cephfs"}

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )



echo ""
line_separator "START - INSTALLING IBM MQ"

oc project tools

cat $SCRIPT_DIR/mq/$MQ_TEMPLATE |
  sed "s#{{NAMESPACE}}#$NAMESPACE#g;" |
  sed "s#{{FILE_STORAGE}}#$FILE_STORAGE#g;" |
  sed "s#{{BLOCK_STORAGE}}#$BLOCK_STORAGE#g;" > $SCRIPT_DIR/mq/orders.yaml

oc apply -f mq/orders.yaml


END=$((SECONDS+3600))
MQ=FAILED
while [ $SECONDS -lt $END ]; do
    MQ_PHASE=$(oc get qmgr orders -n tools -o=jsonpath={'..phase'})
    if [[ $MQ_PHASE == "Running" ]]
    then
      echo "MQ available"
      MQ=SUCCESS
      break
    else
      echo "Waiting for MQ to be available - this may take 5 minutes"
      sleep 60
    fi
done

line_separator "SUCCESS - IBM MQ CREATED"

echo ""


line_separator "START - INSTALLING KAFKA TOPIC"

cat $SCRIPT_DIR/event-streams/kafka-topic.yaml_template |
  sed "s#{{NAMESPACE}}#$NAMESPACE#g;" > $SCRIPT_DIR/event-streams/kafka-topic.yaml

oc apply -f event-streams/kafka-topic.yaml
END=$((SECONDS+3600))
TOPIC=FAILED
while [ $SECONDS -lt $END ]; do
    TOPIC_PHASE=$(oc get kafkatopic.eventstreams.ibm.com products -o=jsonpath={'..conditions[?(@.type=="Ready")].status'})
    if [[ $TOPIC_PHASE == "True" ]]
    then
      echo "Kafka topic available"
      TOPIC=SUCCESS
      break
    else
      echo "Waiting for Kafka topic to be available - this may take 5-10 minutes"
      sleep 60
    fi
done

line_separator "SUCCESS - KAFKA TOPIC CREATED"

echo ""
line_separator "START - INSTALLING KAFKA CONNECT"

oc apply -f event-streams/kafka-users.yaml

scripts/08c-event-streams-kafka-connect-config.sh
scripts/08e-event-streams-kafka-connector-datagen-config.sh

line_separator "SUCCESS - KAFKA CONNECT CREATED"
