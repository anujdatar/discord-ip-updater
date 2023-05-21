#!/bin/sh

. /container-setup.sh
. /discord-update.sh

# add cloudflare-ddns start script to crontab
echo "*/${FREQUENCY} * * * * /discord-update.sh" > /crontab.txt
/usr/bin/crontab /crontab.txt


# start cron
/usr/sbin/crond -f -l 8
