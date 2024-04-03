#!/bin/bash

cat > "/etc/ipsec.d/sno.conf" <<-EOF
conn sno
    left=192.168.124.253
    leftid=%fromcert
    leftrsasigkey=%cert
    leftsubnet=172.16.110.0/24
    leftcert=north
    rightrsasigkey=%cert
    right=192.168.124.37
    rightid=%fromcert
    authby=rsasig
EOF