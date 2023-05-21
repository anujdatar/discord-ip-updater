FROM alpine:latest

LABEL org.opencontainers.image.source="https://github.com/anujdatar/discord-ip-updater"
LABEL org.opencontainers.image.description="Bot to update server IP via discord webhook"
LABEL org.opencontainers.image.author="Anuj Datar <anuj.datar@gmail.com>"
LABEL org.opencontainers.image.url="https://github.com/anujdatar/discord-ip-updater/blob/main/README.md"
LABEL org.opencontainers.image.licenses=MIT

# default env variables
ENV FREQUENCY 5
ENV METHOD ZONE

# install dependencies
RUN apk update && apk add --no-cache curl jq bind-tools

# copy scripts over
COPY scripts /
RUN chmod 700 /container-setup.sh /entry.sh /discord-update.sh

CMD ["/entry.sh"]
