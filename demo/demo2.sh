#!/usr/bin/env bash

oc patch sqlservercluster/project001-sqlserver -n project001 --type=json --patch '[{"op": "replace", "path": "/spec/version", "value":"14.0.2"}]'