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

curlConfiguration="-fsS -m 10 --retry 3"

if [[ -z "$keepDays" ]]; then

	echo "Keep Days is: $keepDays, nothing to do."
    exit 0

fi

# Get date when notifications should be deleted
DateToDeleteNotifications="$(date --date="$keepDays day ago" '+%Y-%m-%d')"

if [[ "$GotifyApplicationId" == "" ]]; then

	GotifyURL="https://$GotifyDomain/message"

else

	GotifyURL="https://$GotifyDomain/application/$GotifyApplicationId/message"

fi

Paging=""

getAllNotifications () {

	# Collect Notifications IDs  and dates pushed to Gotify
	apiCall="$(curl $curlConfiguration "$GotifyURL?token=$GotifyClientToken$Paging" 2>/dev/null)"

	# Outout Number
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

	curl $curlConfiguration -X DELETE "$GotifyURL/$toDelete" -H "X-Gotify-Key:$GotifyClientToken" >> /dev/null
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
