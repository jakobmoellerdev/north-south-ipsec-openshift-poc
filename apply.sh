#!/bin/bash

oc apply -f manifest_master-ipsec-systemd.yaml \
    -f manifest_master-rt-kernel.yaml \
    -f performance-profile.yaml \
    -f manifest_master-ipsec-systemd.yaml