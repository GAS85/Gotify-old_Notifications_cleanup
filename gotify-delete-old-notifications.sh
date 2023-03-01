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

### END OF CONFIGURATION ###


if [[ -f "$CentralConfigFile" ]]; then

	. $CentralConfigFile

fi

while getopts ":hd:a:c:k:gsf:" option; do
	case $option in
		h)	# Help
			echo "Simple Gotify old notifications cleaner."
			echo "By Georgiy Sitnikov."
			echo ""
			echo "Usage: ./gotify-delete-old-notifications.sh [options]"
            echo ""
			echo "Example:"
            echo "For Application ID 10:"
			echo "  ./gotify-delete-old-notifications.sh -a 10"
            echo ""
            echo "... save messages for last 7 days,
    on custom server:"
			echo "  ./gotify-delete-old-notifications.sh -a 10 -k 7 -d server.com/gotify"
            echo ""
            echo "Delete all messages older than 1 year, aka 'globally':"
			echo "  ./gotify-delete-old-notifications.sh -g -k 365"
			echo ""
			echo "Options:"
			echo "  -a <ID>         Set Gotify Application ID. E.g. '10' than messages only
                  for application 10 will be deleted."
			echo "  -k <Number>     Set Number of days to keep messages, all messages older than
                  this number will be deleted.
                  Could not be zero. Default 7."
			echo "  -g              Work Globally for all applications, could not be combined with '-a'."
			echo "  -c              Set Client Token for Gotify."
			echo "  -d              Set Gotify Path and Port as: 'server.com:8080/gotify'."
            echo "                  HTTPS is only supported protocol, you do not need to set it."
			echo "  -f <path>       Custom path to config file, default '/etc/gotify-delete-old-notifications.conf'."
			echo "  -s              Show current active configuration and exit."
			echo "  -h              This help."
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
			echo "Gotify Path:                 $GotifyDomain"
			echo "Gotify Application ID:       $GotifyApplicationId"
			echo "Gotify Client Token:         $(echo $GotifyClientToken | cut -c -4)..."
			echo "Days to keep messages:       $keepDays"
			echo "Expected configuration file: $CentralConfigFile"
			exit 0
			;;
		\?)
			break
			;;
	esac
done

# Set curl Options, like timeout and number of retries
curlConfiguration="-fsS -m 10 --retry 3"

if [[ -z "$keepDays" ]] || [[ "$keepDays" == 0 ]]; then

	echo "Keep Days is not set or Zero, nothing to do."
	exit 1

fi

# Get date when notifications should be deleted
DateToDeleteNotifications="$(date --date="$keepDays day ago" '+%Y-%m-%d')"

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
connectivityCheck="$(curl -m 10 -sL -w "%{http_code}\n" "$GotifyURL?token=$GotifyClientToken" -o /dev/null)"
[[ "$connectivityCheck" == "401" ]] && { echo "ERROR - Unauthorized. Please check Client Token."; exit 1; }
[[ "$connectivityCheck" == "000" ]] && { echo "ERROR - Host not reacheble under https://$GotifyDomain. Please check if Server and Port are correct."; exit 1; }

getAllNotifications () {

	# Collect Notifications IDs and dates pushed to Gotify
	apiCall="$(curl $curlConfiguration "$GotifyURL?token=$GotifyClientToken$Paging" 2>/dev/null)"

	# Output Number
	getIDs="$(echo $apiCall | jq .messages | grep '"id":' | awk '{print $2}' | sed 's/.$//')"

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

	curl $curlConfiguration -X DELETE "$GotifyURLToDelete/$toDelete" -H "X-Gotify-Key:$GotifyClientToken" >> /dev/null
	toDelete=""

}

findExpiredNotifications () {

	COUNT=1

	while read notificationDate; do

		if [[ "$DateToDeleteNotifications" > "$notificationDate" ]]; then

			# Get Notification ID per following Number corresponding Date Following Number
			toDelete="$(echo $getIDs | awk '{ print $'$COUNT' }')"
			deleteNotification

		fi

		((COUNT++));

	done <<< "$getDates" # Read from variable

}

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

exit 0
