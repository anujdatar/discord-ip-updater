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
  echo "[$(date)]: Public IP not found, check internet connection"
  exit 1
fi
# #####################################################################
# Step 2: check against old ip
OLD_IP=$(cat /old_record_ip)
if [ "$OLD_IP" == "$CURRENT_IP" ]; then
  echo "[$(date)]: IP unchanged, not updating.  IP: $CURRENT_IP"
# #####################################################################
# Step 3: send updated ip to discord
else
  curl -s --header "Content-Type:application/json" \
    --request POST \
    --data "{\"content\": \"$MESSAGE $CURRENT_IP\"}" \
    $WEBHOOK

  if [ $? -ne 0 ]; then
    echo "[$(date)]: Discord message failed. Curr IP: $CURRENT_IP"
  else
    echo "[$(date)]: Discord message successful.. IP: $CURRENT_IP"
    echo $CURRENT_IP > /old_record_ip
  fi
fi
