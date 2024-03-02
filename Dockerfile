FROM alpine:3.19

# Install curl, sed, aws, cron
RUN apk update --no-cache && \
    apk add --no-cache \
    curl \
    sed \
    mawk \
    jq \
    busybox \
    bash

COPY Docker/ /
COPY gotify-delete-old-notifications.sh /

RUN echo "Lets make *.sh executable" && \
    chmod +x /*.sh && \
    echo "Lets add jobs to the Crontab" && \
    cat crontab.template >> /etc/crontab && \
    echo "Lets add key to use Alpine" && \
    echo "UseAlpine=true" >> /etc/gotify-delete-old-notifications.conf

USER root:root
HEALTHCHECK none
ENTRYPOINT  ["/docker-run.sh"]
