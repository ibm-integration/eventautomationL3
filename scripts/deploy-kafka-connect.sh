#!/bin/bash
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
line_separator "START - INSTALLING KAFKA CONNECT"

oc apply -f event-streams/kafka-users.yaml

cat $SCRIPT_DIR/event-streams/kafka-connect.yaml_template |
  sed "s#{{NAMESPACE}}#$NAMESPACE#g;" > $SCRIPT_DIR/event-streams/kafka-connect.yaml

oc apply -f event-streams/kafka-connect.yaml
END=$((SECONDS+3600))
KAFKA_CONNECT=FAILED
while [ $SECONDS -lt $END ]; do
    CONNECT_PHASE=$(oc get kafkaconnect.eventstreams.ibm.com kafka-connect-cluster -o=jsonpath={'..conditions[?(@.type=="Ready")].status'})
    if [[ $CONNECT_PHASE == "True" ]]
    then
      echo "Kafka connect available"
      KAFKA_CONNECT=SUCCESS
      break
    else
      echo "Waiting for Kafka connect to be available - this may take 5-10 minutes"
      sleep 60
    fi
done

line_separator "SUCCESS - KAFKA CONNECT CREATED"
