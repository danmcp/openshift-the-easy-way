#!/usr/bin/env bash

openshift-install --help
openshift-install create install-config
openshift-install create manifests
# Edit m4.large and replicas: 1
vi openshift/99_openshift-cluster-api_worker-machineset.yaml
openshift-install create ignition-configs
openshift-install create cluster
