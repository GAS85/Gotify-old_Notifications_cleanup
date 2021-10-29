# Gotify - Older Notifications cleanup

This script allows you to automatically remove old Notifications based on date.
You can specify ApplicationID and remove Notifications for particular Application.

## Configuration

Following configuration is needed. You can keep it directly in script (do not forget to apply `chmod 750` or even `chmod 500`) or in a `CentralConfigFile`.

`GotifyDomain="server.com/gotify"` Your Domain with Path to Gotify. Only HTTPS is supported and not needed to list here.

`GotifyApplicationId=10` Gotify Application ID, please keep it Empty if you would like to perform clean up for all Applications.

`GotifyClientToken="xxxxxxxxxx"` Gotify **Client** Token. It is needed to have right to delete Notifications. Please generate one in Gotify.

`keepDays=7` Days to keep Notifications, E.g., everything older than 7 days will be removed.

`CentralConfigFile="/etc/gotify-delete-old-notifications.conf"` Allows you to move configuration to different location and ensure better security. If `CentralConfigFile` configured and exist it will overrules configuration in script.

## Run it

Simply use command line (do not forget to apply `chmod 750`)

```shell
gotify-delete-old-notifications.sh
```

Or add to the cronjob:

```shell
@daily /usr/local/bin/gotify-delete-old-notifications.sh #Cleanup Gotify notifications
```

## Dependencies 
This script needs: `curl`, `jq`, `awk`, `sed`.
