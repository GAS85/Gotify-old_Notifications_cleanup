# Gotify - Older Notifications cleanup

This script allows you to automatically remove old Notifications based on date.
You can specify ApplicationID and remove Notifications for particular Application.

## Configuration

### Via config file or variables

Following configuration is needed. You can keep it directly in script (do not forget to apply `chmod 750` or even `chmod 500`) or in a `CentralConfigFile`.

`GotifyDomain="server.com/gotify"` Your Domain with Path to Gotify. Only HTTPS is supported and not needed to list here.

`GotifyApplicationId=10` Gotify Application ID, please keep it Empty if you would like to perform cleanups for all Applications.

`GotifyClientToken="xxxxxxxxxx"` Gotify **Client** Token. It is needed to have right to delete Notifications. Please generate one in Gotify.

`keepDays=7` Days to keep Notifications, E.g., everything older than 7 days will be removed.

`CentralConfigFile="/etc/gotify-delete-old-notifications.conf"` Allows you to move configuration to different location and ensure better security. If `CentralConfigFile` configured and exist, it will overrule configuration in script.

### Via parameters

Now you can set parameters to the Script to specify all different variables.

Options could be:

 - `-d` Set Gotify Path and Port as: `server.com:8080/gotify`. HTTPS is only supported protocol, you do not need to set it.
 - `-c <token>` Set Client Token for Gotify.
 - `-a <ID>` Set Gotify Application ID. E.g., `10` than messages only for application 10 will be deleted.
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

Few more examples:

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

## Docker

You can run this in a docker container. It has cron so that script will be executed on a daily basis:

1. Clone this repository:
```bash
git clone <link to the repo>
```
2. Build a container:
```bash
docker build -t gton Gotify-Old_Notifications_cleanup
```
3. Run it:
```bash
docker run -d gton
```

### Docker CLI parameters

You can run this container with CLI parameters similar as for [pure CLI](#run-it), e.g.:

```bash
docker run -it gton -h
# For Application ID 10:
docker run -it gton -a 10
# ... save messages for last 7 days, on custom server:
docker run -it gton -a 10 -k 7 -d server.com/gotify
# Delete all messages older than 1 year, aka 'globally':
docker run -it gton -g -k 365
```

### Persist Configuration

To persist configuration please mount `/etc/gotify-delete-old-notifications.conf` to any place that you need. E.g.:
```bash
docker run -v /your/storage/path/:/etc/gotify-delete-old-notifications.conf gton
```

### Docker Variables

You can configure following variables:

1. `GDON_USE_CRON=false` Enable container with a cron job so it will be executed on daily basis. Without it container will exit after script executed once. Example is:
```bash
docker run -d -e GDON_USE_CRON=true gton
```
In this case CLI parameters will be ignored, please use configuration in [persist configuration](#persist-configuration) file.
2. `GDON_APP_ID=<value>` Set Gotify Application ID. E.g., `10` than messages only for application 10 will be deleted.
3. `GDON_KEEP_DAYS=<value>` Set Number of days to keep messages, all messages older than this number will be deleted. Could not be zero. Default `7`.
4. `GDON_GLOBAL=false` Work Globally for all applications, `GDON_APP_ID` will be ignored in this case.
5. `GDON_CLIENT_TOKEN=<value>` Set Client Token for Gotify.
6. `GDON_DOMAIN=<value>` Set Gotify Path and Port as: `server.com:8080/gotify`. HTTPS is only supported protocol, you do not need to set it.
7. `GDON_SHOW_CONFIG_ONLY=false` Will show current active configuration and exit.
8. `GDON_HELP=false` Will show help and exit.
