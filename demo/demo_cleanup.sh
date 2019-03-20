#!/usr/bin/env bash

# Update the sqlserver version in the CRs
for i in `seq 1 5`;
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

  oc patch sqlservercluster/${project_name}-sqlserver -n ${project_name} --type=json --patch '[{"op": "replace", "path": "/spec/version", "value":"14.0.1"}]'

done

for i in `seq 96 100`;
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

  oc delete project $project_name

done

oc delete project myproject
oc delete csv sqlserveroperator.v14.0.1 -n openshift-operators
oc delete csv sqlserveroperator.v14.0.2 -n openshift-operators
oc delete subscription sqlserver -n openshift-operators
oc delete operatorsources partner-operators -n openshift-marketplace

demo/demo_setup.sh