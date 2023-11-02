#!/bin/bash -e
certutil -A -i /etc/pki/certs/ipsec-ns-ca.pem -n "ipsec-test-ca" -t "CT,," -d sql:/var/lib/ipsec/nss
# this assumes the current node is south, the other node is north
# otherwise turn around north/south
certutil -A -i /etc/pki/certs/ipsec-ns-north.crt -n "north" -t "P,," -d sql:/var/lib/ipsec/nss
pk12util -i /etc/pki/certs/ipsec-ns-south.p12  -d sql:/var/lib/ipsec/nss -W ""