#!/bin/bash

# DNS servers you want
DNS2="1.1.1.1"
DNS1="8.8.8.8"

# Overwrite resolv.conf
cat <<EOF > /etc/resolv.conf
nameserver $DNS1
nameserver $DNS2
EOF

echo "Global DNS set to:"
echo "  $DNS1"
echo "  $DNS2"

