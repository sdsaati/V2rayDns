#!/bin/bash

# DNS servers you want
DNS1="127.0.0.1"

# Overwrite resolv.conf
cat <<EOF > /etc/resolv.conf
nameserver $DNS1
EOF

echo "Global DNS set to:"
echo "  $DNS1"

