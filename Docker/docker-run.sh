#!/bin/bash

echo "Welcome to Gotify Delete Old Notifications (GDON) container.
Original Repository is https://git.sitnikov.eu/gas/Gotify-Old_Notifications_cleanup.
Mirror under: https://github.com/GAS85/Gotify-old_Notifications_cleanup."

#  -s              Show current active configuration and exit.
if [[ "$GDON_SHOW_CONFIG_ONLY" == "true" ]]; then

    ./gotify-delete-old-notifications.sh -s
    exit 0

fi

#  -h              This help.
if [[ "$GDON_HELP" == "true" ]]; then

    ./gotify-delete-old-notifications.sh -h
    exit 0

fi

#  -f <path>       Custom path to config file, default '/etc/gotify-delete-old-notifications.conf'.
if [[ ! -z $GDON_CUSTOM_CONFIG_PATH ]]; then

    echo "To set Gotify custom config path, please mount /etc/gotify-delete-old-notifications.conf to any place that you need.
E.g. docker run -v /your/storage/path/:/etc/gotify-delete-old-notifications.conf ..."
    exit 0

fi

CentralConfigFile="/etc/gotify-delete-old-notifications.conf"

# Update the persisted settings in case it is already set. First remove any old value, then add new.

#  -a <ID>         Set Gotify Application ID. E.g. '10' than messages only
#                  for application 10 will be deleted.
if [[ ! -z $GDON_APP_ID ]]; then

    #GDON_DOMAIN="-a $GDON_APP_ID"
    sed -i '/GotifyApplicationId/d' $CentralConfigFile
    echo "export GotifyApplicationId=$GDON_APP_ID" >> $CentralConfigFile

fi

#  -k <Number>     Set Number of days to keep messages, all messages older than
#                  this number will be deleted.
#                  Could not be zero. Default 7.
if [[ ! -z $GDON_KEEP_DAYS ]]; then

    #GDON_KEEP_DAYS="-k $GDON_KEEP_DAYS"
    sed -i '/keepDays/d' $CentralConfigFile
    echo "export keepDays=$GDON_KEEP_DAYS" >> $CentralConfigFile

fi

#  -g              Work Globally for all applications, could not be combined with '-a'.
if [[ "$GDON_GLOBAL" == "true" ]]; then

    #GDON_GLOBAL="-g"
    sed -i '/keepDays/d' $CentralConfigFile

#else

#    GDON_GLOBAL=""

fi

#  -c              Set Client Token for Gotify.
if [[ "$GDON_CLIENT_TOKEN" == "true" ]]; then

    #GDON_CLIENT_TOKEN="-c $GDON_CLIENT_TOKEN"
    sed -i '/GotifyClientToken/d' $CentralConfigFile
    echo "export GotifyClientToken=$GDON_CLIENT_TOKEN" >> $CentralConfigFile

fi

#  -d              Set Gotify Path and Port as: 'server.com:8080/gotify'.
#                  HTTPS is only supported protocol, you do not need to set it.
if [[ ! -z $GDON_DOMAIN ]]; then

    #GDON_DOMAIN="-d $GDON_DOMAIN"
    sed -i '/GotifyDomain/d' $CentralConfigFile
    echo "export GotifyDomain=$GDON_DOMAIN" >> $CentralConfigFile

fi

# Provide all arguments to the command instead of using of Docker Variables if presented

echo "$(date) - Starting GDON"

if [[ "$GDON_USE_CRON" == "true" ]]; then

    ./gotify-delete-old-notifications.sh

    echo "$(date) - Starting Cron"

    #service cron start
    cron -f -L 15 2>&1

else

    ./gotify-delete-old-notifications.sh $@

fi

exit 0