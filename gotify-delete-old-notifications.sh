#!/bin/bash

# As-is. By Georgiy Sitnikov.

# Gotify URL
GotifyDomain="server.com/gotify"
# Gotify Application ID
# Keep Empty if you would like to clean up for all Applications
GotifyApplicationId=10
# Gotify Client Token
GotifyClientToken="xxxxxxxxxx"
# Days to keep Notifications
keepDays=7

CentralConfigFile="/etc/gotify-delete-old-notifications.conf"

LOCKFILE=/tmp/.gotify-delete-old-notifications.lock

### END OF CONFIGURATION ###

if [[ -f "$CentralConfigFile" ]]; then

	. $CentralConfigFile

fi

while getopts ":hd:a:c:k:gsf:A" option; do
	case $option in
		h)	# Help
			echo "Simple Gotify old notifications cleaner.
By Georgiy Sitnikov.

Usage: ./gotify-delete-old-notifications.sh [options]

Example:
For Application ID 10:
  ./gotify-delete-old-notifications.sh -a 10

... save messages for last 7 days,
    on custom server:
  ./gotify-delete-old-notifications.sh -a 10 -k 7 -d server.com/gotify

Delete all messages older than 1 year, aka 'globally':
  ./gotify-delete-old-notifications.sh -g -k 365

Options:
  -a <ID>         Set Gotify Application ID. E.g. '10' than messages only
                  for application 10 will be deleted.
  -k <Number>     Set Number of days to keep messages, all messages older than
                  this number will be deleted.
                  Could not be zero. Default 7.
  -g              Work Globally for all applications, could not be combined with '-a'.
  -c              Set Client Token for Gotify.
  -d              Set Gotify Path and Port as: 'server.com:8080/gotify'.
                  HTTPS is only supported protocol, you do not need to set it.
  -f <path>       Custom path to config file, default '/etc/gotify-delete-old-notifications.conf'.
  -s              Show current active configuration and exit.
  -h              This help."
			exit 0
			;;
		d)	# set GotifyDomain
			GotifyDomain="$OPTARG"
			;;
		a)	# set GotifyApplicationId
			if [[ "$OPTARG" == "" ]]; then

				echo "You have to set Gotify Application ID, or use '-g' instead. Try '-h' for help"
				exit 1

			else

				GotifyApplicationId="$OPTARG"

			fi
			;;
		c)	# set GotifyClientToken
			GotifyClientToken="$OPTARG"
			;;
		k)	# set keepDays
			keepDays="$OPTARG"
			;;
		g)	# unset GotifyApplicationId to work globally
			GotifyApplicationId=""
			;;
		f)	# set CentralConfigFile
			CentralConfigFile="$OPTARG"
			[[ -r "$CentralConfigFile" ]] || { echo "ERROR - Custom config file is set, but not could not be read under $CentralConfigFile."; exit 1; }
			;;
		s)	# Show current Active Configuration
			echo "Gotify Path:                 https://$GotifyDomain"
			echo "Gotify Application ID:       $GotifyApplicationId"
			echo "Gotify Client Token:         $(echo $GotifyClientToken | cut -c -4)..."
			echo "Days to keep messages:       $keepDays"
			echo "Expected configuration file: $CentralConfigFile"
			exit 0
			;;
		A) # Force Alpine features
			UseAlpine=true
			;;
		\?)
			break
			;;
	esac
done

# LOCKFILE is needed to aviod parallel execution
if [ -f "$LOCKFILE" ]; then
	echo "$(date +"[%d/%M/%Y:%H:%M:%S %z]") - Other sync instance seems running now."
	# Remove lock file if script fails last time and did not run longer than 1 day due to lock file.
	find "$LOCKFILE" -mtime +1 -type f -delete
	exit 0
fi

touch $LOCKFILE

# Set curl Options, like timeout and number of retries
curlConfiguration='-fsSL -m 10 --retry 1 -w \n%{http_code}'

if [[ -z "$keepDays" ]] || [[ "$keepDays" == 0 ]]; then

	echo "Keep Days is not set or Zero, nothing to do."
	exit 1

fi

# Check if I am on Ubuntu or on Alpine. Defalut will be Ubuntu, but for Docker Alpine image used.
if [[ "$UseAlpine" == "true" ]]; then

	# Get date when notifications should be deleted for Alpine based on Seconds
	DateToDeleteNotifications="$(date -d "@$(( $(date +%s) - $keepDays * 24 * 60 * 60 ))" -I)"

else

	# Get date when notifications should be deleted for Ubuntu
	DateToDeleteNotifications="$(date --date="$keepDays day ago" '+%Y-%m-%d')"

fi

# Check if GotifyApplicationId set, use different links to work
if [[ "$GotifyApplicationId" == "" ]]; then

	GotifyURL="https://$GotifyDomain/message"
	GotifyURLToDelete=$GotifyURL

else

	GotifyURL="https://$GotifyDomain/application/$GotifyApplicationId/message"
	GotifyURLToDelete="https://$GotifyDomain/message"

fi

Paging=""

# Connectivity check
ConnectivityCheck () {

	connectivityCheck=${apiCall: -3}

	# This is success
	[[ "$connectivityCheck" == "200" ]] && return

	# This is an error
	[[ "$connectivityCheck" == "400" ]] && { echo "$(date +"[%d/%M/%Y:%H:%M:%S %z]") - ERROR - Bad Request."; rm $LOCKFILE ; exit 1; }
	[[ "$connectivityCheck" == "401" ]] && { echo "$(date +"[%d/%M/%Y:%H:%M:%S %z]") - ERROR - Unauthorized. Please check Client Token."; rm $LOCKFILE ; exit 1; }
	[[ "$connectivityCheck" == "404" ]] && { echo "$(date +"[%d/%M/%Y:%H:%M:%S %z]") - ERROR - Not Found under https://$GotifyDomain."; rm $LOCKFILE ; exit 1; }
	[[ "$connectivityCheck" == "500" ]] && { echo "$(date +"[%d/%M/%Y:%H:%M:%S %z]") - ERROR - Server Error by calling https://$GotifyDomain"; rm $LOCKFILE ; exit 1 ; }
	[[ "$connectivityCheck" == "000" ]] && { echo "$(date +"[%d/%M/%Y:%H:%M:%S %z]") - ERROR - Host not reacheble. Please check if Server and Port are correct. Current config is https://$GotifyDomain"; rm $LOCKFILE ; exit 1 ; }

}

getAllNotifications () {

	# Collect Notifications IDs and dates pushed to Gotify
	apiCall="$(curl $curlConfiguration "$GotifyURL?token=$GotifyClientToken$Paging" 2>&1)"
	ConnectivityCheck
	apiCall=${apiCall::-3}

	# Output Number
	getIDs="$(echo $apiCall | jq .messages | grep '"id":' | awk '{print $2}' | sed 's/.$//')"
	[[ "$getIDs" == "" ]] && { echo "$(date +"[%d/%M/%Y:%H:%M:%S %z]") - WARNING - No IDs were collected."; rm $LOCKFILE ; exit 0; }

	# Output Date with time, e.g.:
	# 2021-10-25
	# similar to date +"%Y-%m-%d"
	getDates="$(echo $apiCall | jq .messages | grep -E '"date"' | awk -F'["]' '{print $4}' | awk -F'[T]' '{print $1}')"

	# URL to get next is .../application/10/message?limit=100&since=6933
	# will be "null" if nothing
	pagingLimit="$(echo $apiCall | jq .paging.limit)"
	# Will be "0" if no following pages needed
	pagingSince="$(echo $apiCall | jq .paging.since)"

}

deleteNotification () {

	apiCall=$(curl $curlConfiguration -X DELETE "$GotifyURLToDelete/$toDelete" -H "X-Gotify-Key:$GotifyClientToken" 2>&1)
	ConnectivityCheck
	toDelete=""

}

allMessagescount=0

findExpiredNotifications () {

	count=1

	while read notificationDate; do

		if [[ "$DateToDeleteNotifications" > "$notificationDate" ]]; then

			# Get Notification ID per following Number corresponding Date Following Number
			toDelete="$(echo $getIDs | awk '{ print $'$count' }')"
			deleteNotification
			((allMessagescount++));

			if (( $allMessagescount % 25 == 0 )); then

				echo "$(date +"[%d/%M/%Y:%H:%M:%S %z]") - INFO - $allMessagescount Messages were removed. Still working..."

			fi

		fi

		((count++));

	done <<< "$getDates" # Read from variable

}

echo "$(date +"[%d/%M/%Y:%H:%M:%S %z]") - INFO - Starting Gotify Delete Old Notifications, will remove notifications before $DateToDeleteNotifications."

while :
do

	getAllNotifications
	findExpiredNotifications

	if [[ "$pagingSince" != 0 ]] && [[ "$pagingSince" != "null" ]]; then

		Paging="&limit=$pagingLimit&since=$pagingSince"

	else

		break

	fi

done

echo "$(date +"[%d/%M/%Y:%H:%M:%S %z]") - INFO - Finished. $allMessagescount Messages were removed."

rm $LOCKFILE

exit 0
