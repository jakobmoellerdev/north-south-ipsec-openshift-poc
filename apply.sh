#!/bin/bash

oc apply -f manifest_master-ipsec-systemd.yaml \
    -f manifest_master-rt-kernel.yaml \
    -f tuned-rt.yaml \
    -f performance-profile.yaml