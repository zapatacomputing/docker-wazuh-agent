#!/bin/bash


# Register agent if client.keys is empty
if [ ! -s /var/ossec/etc/client.keys ]; then
  groups=${JOIN_GROUPS:-default}
  password=""
  if [ ! -z ${JOIN_PASSWORD} ]; then
    password="-P ${JOIN_PASSWORD}"
  fi
  /var/ossec/bin/agent-auth -m $OSSEC_MANAGER_HOST -G $groups $password
fi

echo "config start"
cat /var/ossec/etc/ossec.conf
echo "config end"

sed -i "s/\(<address>\)[^<]*\(<\/address>\)/\1$OSSEC_MANAGER_HOST\2/" /var/ossec/etc/ossec.conf
chown root:ossec /var/ossec/etc/ossec.conf

# Start the agent
/var/ossec/bin/ossec-control start
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start agent: $status : printing logs start"
  cat /var/ossec/logs/*
  echo "config start"
  cat /var/ossec/etc/ossec.conf
  echo "config end"
  ls -la /var/ossec/etc/
  echo "Failed to start agent: $status : printing logs end"
  exit $status
fi

echo "background jobs running, listening for changes"

while sleep 60; do
  /var/ossec/bin/ossec-control status > /dev/null 2>&1
  status=$?
  if [ $status -ne 0 ]; then
    echo "looks like the agent died."
    exit 1
  fi
done
