#!/bin/sh

. /config.sh

# #####################################################################
# Step 1: Get the current IP address
echo fetching current IP address


if [ "$RECORD_TYPE" == "A" ]; then
	CURRENT_IP=$(curl -s https://api.ipify.org || curl -s https://ipv4.icanhazip.com/)

	# check cloudflare's dns server if above method doesn't work
	if [ -z $CURRENT_IP ]; then
		echo using cloudflare whoami to find ip
    CURRENT_IP=$(dig txt ch +short whoami.cloudflare @1.1.1.1 | tr -d '"')
	fi
elif [ "$RECORD_TYPE" == "AAAA" ]; then
	CURRENT_IP6=$(curl -s https://api6.ipify.org || curl -s https://ipv6.icanhazip.com/)

	# check cloudflare's dns server if above method doesn't work
	if [ -z $CURRENT_IP6 ]; then
		echo using cloudflare whoami to find ip
    CURRENT_IP6=$(dig txt ch +short whoami.cloudflare @2606:4700:4700::1111 | tr -d '"')
	fi
fi

if [ $? -ne 0 ]; then
  echo "Error fetching current IP address"
  exit 1
fi

if [ ! -z $CURRENT_IP6 ]; then
  CURRENT_IP=$(echo $CURRENT_IP6 | sed -r 's/[:]+/-/g')
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
