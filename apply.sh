#!/bin/bash

oc apply -f manifest_master-ipsec-systemd.yaml \
    -f manifest_worker-ipsec-systemd.yaml \
    -f manifest_master-rt-kernel.yaml \
    -f manifest_worker-rt-kernel.yaml