FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive

# Setting Defaults
ENV TZ="Europe/Berlin"

# Install curl, sed, aws, cron
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    sed \
    mawk \
    jq \
    cron && \
    rm -rf /var/lib/apt/lists/*
    
COPY Docker/ / \
     gotify-delete-old-notifications.sh /

RUN echo "Lets make *.sh executable" && \
    chmod +x /*.sh && \
    echo "Lets add jobs to the Crontab" && \
    cat crontab.template >> /etc/crontab

USER root:root
HEALTHCHECK none
ENTRYPOINT  ["/docker-run.sh"]
