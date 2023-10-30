#!/bin/bash

CANAME="ipsec-test-ca"
SOUTH="south"
NORTH="north"

FOLDER="./$CANAME"

rm -r $FOLDER
mkdir $FOLDER

certutil -S -k rsa -n $CANAME -s "CN=ca" -v 12 -t "CT,C,C" -x -d $FOLDER
certutil -S -k rsa -c $CANAME -n $SOUTH -s "CN=$SOUTH" -v 12 -t "u,u,u" -d $FOLDER
certutil -S -k rsa -c $CANAME -n $NORTH -s "CN=$NORTH" -v 12 -t "u,u,u" -d $FOLDER

pk12util -n $SOUTH -d $FOLDER -o $FOLDER/$SOUTH.p12
certutil -L -n $CANAME -d $FOLDER -a > $FOLDER/$CANAME.crt
certutil -L -n $NORTH -d $FOLDER -a > $FOLDER/$NORTH.crt
pk12util -n $NORTH -d $FOLDER -o $FOLDER/$NORTH.p12
certutil -L -n $SOUTH -d $FOLDER -a > $FOLDER/$SOUTH.crt