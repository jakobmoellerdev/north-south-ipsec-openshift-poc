#!/bin/bash


cat > "ipsec-master-endpoint-config.bu" <<-EOF
variant: openshift
version: 4.14.0
metadata:
  name: 99-master-ipsec-certs
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
  - path: /usr/local/bin/ipsec-addcert.sh
    mode: 0740
    overwrite: true
    contents:
      inline: |
        #!/bin/bash -e
        certutil -A -i /etc/pki/certs/ipsec-ns-ca.pem -n "ipsec-test-ca" -t "CT,," -d sql:/var/lib/ipsec/nss
        ## this assumes the current node is south, the other node is north
        ## otherwise turn around north/south
        ## certutil -A -i /etc/pki/certs/ipsec-ns-north.crt -n "north" -t "P,," -d sql:/var/lib/ipsec/nss
        pk12util -i /etc/pki/certs/ipsec-ns-south.p12  -d sql:/var/lib/ipsec/nss -W ""
EOF

butane ipsec-master-endpoint-config.bu -o ./99-master-ipsec-certs.yaml -d ./ipsec-test-ca

rm ipsec-master-endpoint-config.bu