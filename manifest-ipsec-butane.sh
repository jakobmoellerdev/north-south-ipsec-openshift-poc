#!/bin/bash


cat > "ipsec-master-endpoint-config.bu" <<-EOF
variant: openshift
version: 4.14.0
metadata:
  name: 99-master-ipsec
  labels:
    machineconfiguration.openshift.io/role: master
openshift:
  extensions:
    - ipsec
systemd:
  units:
  - name: ipsec-import.service
    enabled: true
    contents: |
      [Unit]
      Description=Import external certs into ipsec NSS
      Before=ipsec.service
      [Service]
      Type=oneshot
      ExecStart=/usr/local/bin/ipsec-addcert.sh
      RemainAfterExit=false
      StandardOutput=journal
      [Install]
      WantedBy=multi-user.target
  - name: ipsec-enabler.service
    enabled: true
    contents: |
      [Service]
      Type=oneshot
      ExecStart=systemctl enable --now ipsec.service
      [Install]
      WantedBy=multi-user.target
  - name: ipsec-configure.service
    enabled: true
    contents: |
      [Unit]
      Description=Configure IPSec for host-to-host cert authentication
      After=ipsec-enabler.service
      [Service]
      Type=oneshot
      ExecStart=/usr/local/bin/ipsec-configure.sh
      RemainAfterExit=false
      StandardOutput=journal
      [Install]
      WantedBy=multi-user.target
storage:
  files:
  - path: /etc/pki/certs/ipsec-ns-ca.pem
    mode: 0400
    overwrite: true
    contents:
      local: ipsec-test-ca.crt
  - path: /etc/pki/certs/ipsec-ns-south.p12
    mode: 0400
    overwrite: true
    contents:
      local: south.p12
  - path: /etc/pki/certs/ipsec-ns-north.crt
    mode: 0400
    overwrite: true
    contents:
      local: north.crt
  - path: /etc/ipsec.d/host-to-host-cert.conf
    mode: 0740
    overwrite: true
    contents:
      local: ipsec.conf
  - path: /usr/local/bin/ipsec-addcert.sh
    mode: 0740
    overwrite: true
    contents:
      local: ipsec-import.sh
  - path: /usr/local/bin/ipsec-configure.sh
    mode: 0740
    overwrite: true
    contents:
      local: ipsec-configure.sh
EOF

butane ipsec-master-endpoint-config.bu -o ./manifest_master-ipsec-systemd.yaml -d ./ipsec-test-ca

rm ipsec-master-endpoint-config.bu