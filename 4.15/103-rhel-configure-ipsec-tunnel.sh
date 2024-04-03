#!/bin/bash -e

sudo systemctl enable ipsec
sudo systemctl start ipsec

sudo ipsec auto --add sno
sudo ipsec auto --up sno