NSSDIR="/var/lib/ipsec/nss"
[ ! -f /etc/ipsec.d/cert9.db ] && ipsec initnss --nssdir ${NSSDIR} || echo
certutil -A -i ./ipsec-test-ca/ipsec-test-ca.crt -n "ipsec-test-ca" -t "CT,," -d sql:${NSSDIR} # /etc/ipsec.d is the location of the nss db, you should use the default showing when running ipsec initnss --help
# this assumes the current node is north, the other node is south
certutil -A -i ./ipsec-test-ca/south.crt -n "south" -t "P,," -d sql:${NSSDIR}
pk12util -i./ipsec-test-ca/north.p12 -d sql:${NSSDIR} -W ""
cp ./ipsec-test-ca/ipsec.conf /etc/ipsec.d/host-to-host-cert.conf