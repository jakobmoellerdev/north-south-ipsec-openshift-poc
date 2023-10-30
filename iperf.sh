#!/bin/bash

#rpm2cpio iperf3-3.1.3-1.fc24.x86_64.rpm | cpio -D ./iperf/ -idmv
butane iperf.bu -o iperf.yaml -d ./iperf