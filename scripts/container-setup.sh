#!/bin/sh

print_breaker() {
    echo "-----------------------------------------------"
}

echo "Container spun up at: [$(date)]"
# #####################################################################
# Step 1: set up timezone
if [ -z "$TZ" ]; then
  echo "TZ environment variable not set. Using default: UTC"
else
  echo "Setting timezone to $TZ"
  ln -snf /usr/share/zoneinfo/$TZ /etc/localtime
  echo $TZ > /etc/timezone
fi

echo "Starting Discord-IP-Updater: [$(date)]"
print_breaker
if [ -f "$WEBHOOK_FILE" ]; then
  WEBHOOK=$(cat $WEBHOOK_FILE)
fi
if [ -z "$WEBHOOK" ]; then
  echo "Please enter valid WEBHOOK env variable or WEBHOOK_FILE secret"
  exit 1
else
  echo "Webhook    --- OK"
fi

# 2. Record Type
if [ "$RECORD_TYPE" == "A" ]; then
  echo "Record type to be updated: A (IPv4)"
elif [ "$RECORD_TYPE" == "AAAA" ]; then
  echo "Record type to be updated: AAAA (IPv6)"
else
  RECORD_TYPE="A"
  echo "Unknown record type, assuming A-record (IPv4)"
fi

# 3. Message
if [ -z "$MESSAGE" ]; then
  MESSAGE="server ip update: "
fi

# #####################################################################
# Step 2: Save to config file
print_breaker
touch /old_record_ip

echo "WEBHOOK=\"$WEBHOOK\"" > /config.sh
echo "RECORD_TYPE=\"$RECORD_TYPE\"" >> /config.sh
echo "MESSAGE=\"$MESSAGE\"" >> /config.sh
# #####################################################################

echo "Discord webhook container setup complete"
print_breaker
print_breaker
