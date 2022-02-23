# Gotify - Older Notifications cleanup

This script allows you to automatically remove old Notifications based on date.
You can specify ApplicationID and remove Notifications for particular Application.

## Configuration

### Via config file or variables

Following configuration is needed. You can keep it directly in script (do not forget to apply `chmod 750` or even `chmod 500`) or in a `CentralConfigFile`.

`GotifyDomain="server.com/gotify"` Your Domain with Path to Gotify. Only HTTPS is supported and not needed to list here.

`GotifyApplicationId=10` Gotify Application ID, please keep it Empty if you would like to perform clean up for all Applications.

`GotifyClientToken="xxxxxxxxxx"` Gotify **Client** Token. It is needed to have right to delete Notifications. Please generate one in Gotify.

`keepDays=7` Days to keep Notifications, E.g., everything older than 7 days will be removed.

`CentralConfigFile="/etc/gotify-delete-old-notifications.conf"` Allows you to move configuration to different location and ensure better security. If `CentralConfigFile` configured and exist it will overrules configuration in script.

### Via parameters

Now you are able to set parameters to the Script to specify all of different variables.

Options coul be:

 - `-d` Set Gotify Path and Port as: `server.com:8080/gotify`. HTTPS is only supported protocol, you do not need to set it.
 - `-c <token>` Set Client Token for Gotify.
 - `-l <ID>` Set Gotify Application ID. E.g. `10` than messages only for application 10 will be deleted.
 - `-k <Number>` Set Number of days to keep messages, all messages older than this number will be deleted. Could not be zero. Default `7`.
 - `-g` Work Globally for all applications, could not be combined with `-a`.
 - `-f <path>` Custom path to config file, default `/etc/gotify-delete-old-notifications.conf`.
 - `-s` Show current active configuration and exit. E.g.:
    ```bash
    ./gotify-delete-old-notifications.sh -s
    Gotify Domain:               server.com/gotify
    Gotify Application ID:       10
    Gotify Client Token:         xxxx...
    Days to keep messages:       7
    Expected configuration file: /etc/gotify-delete-old-notifications.conf
    ```
 - `-h` Help."

## Run it

Simply use command line (do not forget to apply `chmod 750`)

```bash
gotify-delete-old-notifications.sh
```

Or add to the cronjob:

```bash
@daily /usr/local/bin/gotify-delete-old-notifications.sh #Cleanup Gotify notifications
```

Few more exampels:

```bash
# For Application ID 10:
./gotify-delete-old-notifications.sh -a 10
# ... save messages for last 7 days, on custom server:
./gotify-delete-old-notifications.sh -a 10 -k 7 -d server.com/gotify
# Delete all messages older than 1 year, aka 'globally':
./gotify-delete-old-notifications.sh -g -k 365
```

## Dependencies 
This script needs: `curl`, `jq`, `awk`, `sed`.
