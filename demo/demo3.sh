#!/usr/bin/env bash

# Update the sqlserver version in the CRs
for i in `seq 2 100`;
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

  oc patch sqlservercluster/${project_name}-sqlserver -n ${project_name} --type=json --patch '[{"op": "replace", "path": "/spec/version", "value":"14.0.2"}]'

done