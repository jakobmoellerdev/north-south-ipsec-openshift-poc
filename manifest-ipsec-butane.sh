#!/bin/bash

for role in master worker; do
  rm "ipsec-${role}-endpoint-config.bu"
  cat >> "ipsec-${role}-endpoint-config.bu" <<-EOF
variant: openshift
version: 4.14.0
metadata:
  name: 80-${role}-ipsec
  labels:
    machineconfiguration.openshift.io/role: $role
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
  - name: ipsecenabler.service
    enabled: true
    contents: |
      [Service]
      Type=oneshot
      ExecStart=systemctl enable --now ipsec.service
      [Install]
      WantedBy=multi-user.target
storage:
  files:
  - path: /etc/pki/certs/ca.pem
    mode: 0400
    overwrite: true
    contents:
      local: ipsec-test-ca.crt
  - path: /etc/pki/certs/south.p12
    mode: 0400
    overwrite: true
    contents:
      local: south.p12
  - path: /etc/pki/certs/north.crt
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
        certutil -A -i /etc/pki/certs/ca.pem -n "ipsec-test-ca" -t "CT,," -d sql:/var/lib/ipsec/nss
        # this assumes the current node is south, the other node is north
        # otherwise turn around north/south
        certutil -A -i north.crt -n "north" -t "P,," -d sql:/var/lib/ipsec/nss
        ipsec import ./south.p12 --nssdir /var/lib/ipsec/nss
EOF
done
for role in master worker; do
  butane ipsec-${role}-endpoint-config.bu -o ./manifest_$role-ipsec-systemd.yaml -d ./ipsec-test-ca
done