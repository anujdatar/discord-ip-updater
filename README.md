# Discord IP Updater

Get discord updates on ip changes for server using a webhook, via a docker container.

Container packages available from Docker Hub and Github Container Registry (ghcr.io)
  - Docker Hub Image: `anujdatar/discord-ip-updater`
  - GHCR Image: `ghcr.io/anujdatar/discord-ip-updater`

## Parameters / Environment Variables
| # | Parameter | Default | Notes | Description |
| - | --------- | ------- | ----- | ----------- |
| 1 | Frequency | 5 | OPTIONAL | how often you want to run the IP check and send discord message (default = every 5 minutes) |
| 2 | WEBHOOK | - | REQUIRED | Your discord webhook URL |
| 3 | TZ | UTC | OPTIONAL | timezone so container logs can be in local TZ |
| 4 | RECORD_TYPE | A | OPTIONAL | Record types supported: A (IPv4) and AAAA (IPv6) |
| 5 | MESSAGE | "server ip update: " | OPTIONAL | Customizable message string, updated IP will be attached at the end of the message |

## Usage examples
IPv4 updates using `docker-cli`
```bash
docker run -d \
  -e WEBHOOK=<your-discord-webhook> \
  -e TZ=America/New_York \
  --restart unless-stopped \
  --name discord-ip-updater \
  ghcr.io/anujdatar/discord-ip-updater
```

Just a quick spin up for IPv4 updates using `docker-compose`
```yml
version: "3"
services:
  discord-ip-updater:
    image: ghcr.io/anujdatar/discord-ip-updater
    container_name: discord-ip-updater
    restart: unless-stopped
    environment:
      - WEBHOOK=https://discord.com/api/webhooks/<rest-of-your-webhook>
      - MESSAGE=Server IP updated to-
```

For IPv6 updates with secrets, You need to change quite a bit more.
```yml
version: "3"
services:
  discord-ip-updater:
    image: ghcr.io/anujdatar/discord-ip-updater
    container_name: discord-ip-updater
    restart: unless-stopped
    environment:
      - WEBHOOK_FILE=/run/secrets/webhook
      - TZ=America/New_York
      - RECORD_TYPE=AAAA
      - FREQUENCY=1
      - MESSAGE=Server IP updated to-
    secrets:
      - webhook

networks:
  default:
    driver: bridge
    enable_ipv6: true
    ipam:
      driver: default
      config:
        - subnet: fd00::/64

secrets:
  webhook:
    file: webhook.txt
```
### webhook.txt
```txt
https://discord.com/api/webhooks/<rest-of-your-webhook>
```
## Using IPv6
Docker by default only has IPv4 enabled. So containers can only access the web through IPv4. IPv6 traffic is not available by default. There are a few ways you can enable this, these are the quickest I found. I will link official docs where possible.

First you will have to allow IPv6 internet access to the docker subnet on your Host machine. Assuming the private Docker subnet we assign in the steps below is `fd00::/64`. You can use a different subnet if you wish. Or you may need to use a different subnet if you have multiple docker networks with IPv6 enabled.

> NOTE: If you use `ufw` on your system, you will need some additional settings. Please read [section](#ipv6-with-ufw)


```bash
ip6tables -t nat -A POSTROUTING -s fd00::/64 -j MASQUERADE
```
This setting is not persistent, and will not survive a reboot. To make it persistent

```bash
# install iptables-persistent and netfilter-persistent
sudo apt-get install iptables-persistent netfilter-persistent

# save you rules
sudo iptables-save > /etc/iptables/rules.v4
sudo ip6tables-save > /etc/iptables/rules.v6

# restart services
sudo systemctl restart netfilter-persistent

# if you need to restore backed-up rules
sudo iptables-restore < /etc/iptables/rules.v4
sudo ip6tables-restore < /etc/iptables/rules.v6
```
For more information on persistent rules or iptables on RPM based systems, refer to
[1](https://askubuntu.com/questions/1052919/iptables-reload-restart-on-ubuntu/1072948#1072948)
and [2](https://linuxconfig.org/how-to-make-iptables-rules-persistent-after-reboot-on-linux)

For more on IPv6 and docker you can check out this [medium](https://medium.com/@skleeschulte/how-to-enable-ipv6-for-docker-containers-on-ubuntu-18-04-c68394a219a2) article. I do not expose individual docker containers to internet via IPv6 directly, but the article goes over ways to do this. If you need it.

### 1. Enable IPv6 on the default bridge network
Source: [Docker Docs - IPv6](https://docs.docker.com/config/daemon/ipv6/)
1. Edit `etc/docker/daemon.json` and add the following
   ```json
    {
      "ipv6": true,
      "fixed-cidr-v6": "fd00::/64"
    }
   ```
2. Reload the docker config file
   ```bash
   systemctl reload docker
   # or restart the docker service
   systemctl restart docker
   ```
3. You can now start any container connected to the default bridge. You should have IPv6 access. To connect a docker-compose container to default bridge, add `network_mode: bridge` option to the service.

### 2. Create a new persistent network with IPv6 access
In case you want to keep your networks separate.
```bash
docker network create --subnet=172.16.2.0/24 --gateway=172.16.2.1 --ipv6 --subnet=fd00::/64 ipv6bridge
```
You can now connect your container to this network using `--network ipv6bridge`. Or in your `docker-compose.yml` file using
```yaml
services:
  your-service-name:
    image: xyz
    other-options: options
    networks:
      - my-net

networks:
  my-net:
    external:
      name: ipv6bridge
```

or
```yaml
services:
  your-service-name:
    image: xyz
    other-options: options

networks:
  default:
    external:
      name: ipv6bridge
```

### 3. Define the network in your `docker-compose` file
This will be a disposable network, and will be removed when you stop your application. This example changes the default network of all the services in the application. You can create a named network and assign it to services individually as well.

Source: [Docker Compose Networking](https://docs.docker.com/compose/networking/)
```yaml
services:
  your-service-name:
    image: xyz
    other-options: options

networks:
  default:
    driver: bridge
    enable_ipv6: true
    ipam:
      driver: default
      config:
        - subnet: fd00::/64
```

## IPv6 with ufw
UFW seems to have an issue properly routing ipv6 traffic to docker networks. This is what worked for me after a lot of trial and error. Since most of it similar to the section above, I'll try keep it brief.

### 1. Enable IPv6 on the default bridge network
Assuming your default docker network interface is `docker0` (check using `ip a`), and you're still using the same `fd00::/64` subnet.

1. Edit `etc/docker/daemon.json` and add the following
   ```json
    {
      "ipv6": true,
      "fixed-cidr-v6": "fd00::/64"
    }
   ```
2. Reload the docker config file
   ```bash
   systemctl reload docker
   # or restart the docker service
   systemctl restart docker
   ```
3. Update `ufw` and `iptables` settings
   ```bash
   sudo ufw route allow in on docker0
   sudo ip6tables -t nat -A POSTROUTING -s fd00::/64 -j MASQUERADE
   sudo iptables -t mangle -A FORWARD -i docker0 -o end0 -j ACCEPT
   sudo iptables -t mangle -A FORWARD -i end0 -o docker0 -j ACCEPT

   # install iptables-persistent and netfilter-persistent
   sudo apt-get install iptables-persistent netfilter-persistent
   ```


### 2. Create a new persistent network with IPv6 access
In case you want to keep your networks separate. Assuming you're still using the same `fd00::/64` subnet. To keep things repeatable you might also want to assign a name to your new network interface instead of some default like `br-451d9eb3tes8`. I'll call it `ipv6-bridge`.

> NOTE: network interface name is different from the docker network name. you can check the name after you've created the network using `ip a`

```bash
docker network create --subnet=172.16.2.0/24 --gateway=172.16.2.1 --ipv6 --subnet=fd00::/64 --opt com.docker.network.bridge.name=ipv6-bridge ipv6bridge
```

Update `ufw` and `iptables` settings
```bash
sudo ufw route allow in on ipv6-bridge
sudo ip6tables -t nat -A POSTROUTING -s fd00::/64 -j MASQUERADE
sudo iptables -t mangle -A FORWARD -i ipv6-bridge -o end0 -j ACCEPT
sudo iptables -t mangle -A FORWARD -i end0 -o ipv6-bridge -j ACCEPT

# install iptables-persistent and netfilter-persistent
sudo apt-get install iptables-persistent netfilter-persistent
```

You can now connect your container to this network using `--network ipv6bridge`. Or in your `docker-compose.yml` file using

```yaml
services:
  your-service-name:
    image: xyz
    other-options: options

networks:
  default:
    external:
      name: ipv6bridge
```
### 3. Define the network in your `docker-compose` file
This will be a disposable network, and will be removed when you stop your application.

Again, assuming you use the subnet `fd00::/64` and use `ipv6-bridge` for the interface name.

Add `ufw` and `iptables` rules
```bash
sudo ufw route allow in on ipv6-bridge
sudo ip6tables -t nat -A POSTROUTING -s fd00::/64 -j MASQUERADE
sudo iptables -t mangle -A FORWARD -i ipv6-bridge -o end0 -j ACCEPT
sudo iptables -t mangle -A FORWARD -i end0 -o ipv6-bridge -j ACCEPT

# install iptables-persistent and netfilter-persistent
sudo apt-get install iptables-persistent netfilter-persistent
```

Source: [Docker Compose Networking](https://docs.docker.com/compose/networking/)
```yaml
services:
  your-service-name:
    image: xyz
    other-options: options

networks:
  default:
    driver: bridge
    enable_ipv6: true
    ipam:
      driver: default
      config:
        - subnet: fd00::/64
    driver_opts:
      com.docker.network.bridge.name: ipv6-bridge
```

---

## Building
```
docker build -t discord-ip-updater .
```
