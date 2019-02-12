#!/usr/bin/env bash

# pre reqs: Login to a cluster with oc

oc patch clusterversion/version --patch '{"spec":{"upstream":"https://origin-release.svc.ci.openshift.org/graph"}}' --type=merge

oc create -f ../openshift-the-easy-way/assets/cluster-autoscaler.yaml

oc create -f ../openshift-the-easy-way/assets/machine-autoscale-us-east-1a.yaml
oc create -f ../openshift-the-easy-way/assets/machine-autoscale-us-east-1b.yaml
oc create -f ../openshift-the-easy-way/assets/machine-autoscale-us-east-1c.yaml


#Create users jessica:jessica and dan:dan
oc apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: htpass-secret
  namespace: openshift-config
data:
  htpasswd: amVzc2ljYTokYXByMSQ4dGFZNWxTbCR1UndLNi9ieUd4c1JUallrRVE0WVYxCmRhbjokYXByMSRkSEthL3pEbiQwY0Z6NHFvTFZmMGd6OFFpcXlZSU4wCg==
EOF

oc apply -f - <<EOF
apiVersion: config.openshift.io/v1
kind: OAuth
metadata:
  name: cluster
spec:
  identityProviders:
  - name: htpassidp
    challenge: true
    login: true
    mappingMethod: claim
    type: HTPasswd
    htpasswd:
      fileData:
        name: htpass-secret
EOF

# Increase default size of the cluster
oc get machinesets -n openshift-machine-api to 
oc patch machineset/rhsummit2019-czj2q-worker-us-east-1a -n openshift-machine-api --type=json --patch '[{"op": "replace", "path": "/spec/replicas", "value":2}]'
oc patch machineset/rhsummit2019-czj2q-worker-us-east-1b -n openshift-machine-api --type=json --patch '[{"op": "replace", "path": "/spec/replicas", "value":2}]'
oc patch machineset/rhsummit2019-czj2q-worker-us-east-1c -n openshift-machine-api --type=json --patch '[{"op": "replace", "path": "/spec/replicas", "value":2}]'


# Create projects
for i in `seq 1 100`;
do
  if [ $i -lt 10 ]
  then
    project_name=project00${i}
  elif [ $i -lt 100 ]
  then
    project_name=project0${i}
  else
    project_name=project${i}
  fi
  oc new-project $project_name
done


# Create a CR in each project
for i in `seq 1 100`;
do
  if [ $i -lt 10 ]
  then
    project_name=project00${i}
  elif [ $i -lt 100 ]
  then
    project_name=project0${i}
  else
    project_name=project${i}
  fi

  oc create -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: amq-streams
  namespace: $project_name
spec:
  channel: final
  installPlanApproval: Manual
  name: amq-streams
  source: installed-redhat-default
  sourceNamespace: $project_name
  startingCSV: amqstreams.v1.0.0
EOF

  oc create -f - <<EOF
apiVersion: kafka.strimzi.io/v1alpha1
kind: Kafka
metadata:
  name: my-cluster
  namespace: $project_name
spec:
  kafka:
    replicas: 3
    listeners:
      plain: {}
      tls: {}
    config:
      offsets.topic.replication.factor: 3
      transaction.state.log.replication.factor: 3
      transaction.state.log.min.isr: 2
    storage:
      type: ephemeral
  zookeeper:
    replicas: 3
    storage:
      type: ephemeral
  entityOperator:
    topicOperator: {}
    userOperator: {}
EOF

done