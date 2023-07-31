#!/bin/sh

. /config.sh

# #####################################################################
# functions to get public ip
get_ip4() {
  CURRENT_IP=$(curl -s https://ipv4.icanhazip.com/ || curl -s https://api.ipify.org)
  if [ -z $CURRENT_IP ]; then
    dig_ip=$(dig txt ch +short whoami.cloudflare @1.1.1.1)
    if [ "$?" = 0 ]; then
      CURRENT_IP=$(echo $dig_ip | tr -d '"')
    else
      exit 1
    fi
  fi
  echo $CURRENT_IP
}

get_ip6() {
  CURRENT_IP=$(curl -s https://ipv6.icanhazip.com/ || curl -s https://api6.ipify.org)
  if [ -z $CURRENT_IP ]; then
    dig_ip=$(dig txt ch +short whoami.cloudflare @2606:4700:4700::1111)
    if [ "$?" = 0 ]; then
      CURRENT_IP=$(echo $dig_ip | tr -d '"')
    else
      exit 1
    fi
  fi
  echo $CURRENT_IP
}
# #####################################################################
# Step 1: Get the current IP address
if [ "$RECORD_TYPE" == "A" ]; then
	CURRENT_IP=$(get_ip4)
elif [ "$RECORD_TYPE" == "AAAA" ]; then
	CURRENT_IP=$(get_ip6)
fi

if [ -z $CURRENT_IP ]; then
    echo "No public IP found: check internet connection or network settings"
    exit 1
fi
echo "Current time: [$(date)]"
echo "Current Public IP: $CURRENT_IP"
# #####################################################################


# #####################################################################
# Step 2: Send discord message if IP has changed
OLD_IP=$(cat /old_record_ip)
echo "Stored IP address $OLD_IP"

if [ "$OLD_IP" == "$CURRENT_IP" ]; then
  echo "IP address has not changed. Update not required"
else
  echo "Sending updated IP to discord"

  curl -s --header "Content-Type:application/json" \
    --request POST \
    --data "{\"content\": \"$MESSAGE $CURRENT_IP\"}" \
    $WEBHOOK

  if [ $? -ne 0 ]; then
    echo "Error sending message to discord"
    # exit 1
  else
    echo "success"
  fi
fi
