FROM alpine:latest

LABEL org.opencontainers.image.source="https://github.com/anujdatar/discord-ip-updater"
LABEL org.opencontainers.image.description="Bot to update server IP via discord webhook"
LABEL org.opencontainers.image.author="Anuj Datar <anuj.datar@gmail.com>"
LABEL org.opencontainers.image.url="https://github.com/anujdatar/discord-ip-updater/blob/main/README.md"
LABEL org.opencontainers.image.licenses=MIT

# default env variables
ENV FREQUENCY 5
ENV RECORD_TYPE A

# install dependencies
RUN apk update && apk add --no-cache tzdata curl bind-tools jq

# copy scripts over
COPY scripts /
RUN chmod 700 /entry.sh /container-setup.sh /discord-update.sh

CMD ["/entry.sh"]
