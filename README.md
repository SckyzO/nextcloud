# NextCloud 

## sckyzo/nextcloud

### Features

* Based on Alpine Linux.
* Bundled with nginx and PHP 7.4 (sckyzo/nginx-php image).
* Automatic installation using environment variables.
* Package integrity (SHA512) and authenticity (PGP) checked during building process.
* Data and apps persistence.
* OPCache (opcocde), APCu (local) installed and configured.
* system cron task running.
* MySQL, PostgreSQL (server not built-in) and sqlite3 support.
* Redis, FTP, SMB, LDAP, IMAP support.
* GNU Libiconv for php iconv extension (avoiding errors with some apps).
* No root processes. Never.
* Environment variables provided (see below).

### Tags
* **latest** : latest stable version. (recommanded)
* **17** : latest 17.x version (currently stable)
* **16** : latest 16.x version (older stable)

### Build-time variables
- **NEXTCLOUD_VERSION** : version of nextcloud
- **GNU_LIBICONV_VERSION** : version of GNU Libiconv
- **GPG_nextcloud** : signing key fingerprint

### Environment variables
- **UID** : nextcloud user id *(default : 1000)*
- **GID** : nextcloud group id *(default : 998)*
- **UPLOAD_MAX_SIZE** : maximum upload size *(default : 10G)*
- **APC_SHM_SIZE** : apc memory size *(default : 128M)*
- **OPCACHE_MEM_SIZE** : opcache memory size in megabytes *(default : 128)*
- **MEMORY_LIMIT** : php memory limit *(default : 512M)*
- **CRON_PERIOD** : time interval between two cron tasks *(default : 15m)*
- **CRON_MEMORY_LIMIT** : memory limit for PHP when executing cronjobs *(default : 1024m)*
- **TZ** : the system/log timezone *(default : Etc/UTC)*
- **ADMIN_USER** : username of the admin account *(default : none, web configuration)*
- **ADMIN_PASSWORD** : password of the admin account *(default : none, web configuration)*
- **DOMAIN** : domain to use during the setup *(default : localhost)*
- **DB_TYPE** : database type (sqlite3, mysql or pgsql) *(default : sqlite3)*
- **DB_NAME** : name of database *(default : none)*
- **DB_USER** : username for database *(default : none)*
- **DB_PASSWORD** : password for database user *(default : none)*
- **DB_HOST** : database host *(default : none)*

Don't forget to use a **strong password** for the admin account!

### Port
- **8888** : HTTP Nextcloud port.

### Volumes
- **/data** : Nextcloud data.
- **/config** : config.php location.
- **/apps2** : Nextcloud downloaded apps.
- **/nextcloud/themes** : Nextcloud themes location.
- **/php/session** : php session files.

### Database
Basically, you can use a database instance running on the host or any other machine. An easier solution is to use an external database container. I suggest you to use MariaDB, which is a reliable database server. You can use the official `mariadb` image available on Docker Hub to create a database container, which must be linked to the Nextcloud container. PostgreSQL can also be used as well.


## Setup

### Docker run

Pull the image and create a container. `/docker` can be anywhere on your host, this is just an example. Change `MYSQL_ROOT_PASSWORD` and `MYSQL_PASSWORD` values (mariadb). You may also want to change UID and GID for Nextcloud, as well as other variables (see *Environment Variables*).

```
docker pull sckyzo/nextcloud:latest && docker pull mariadb:latest
```
```

docker run -d --name db_nextcloud \
       -v /docker/nextcloud/db:/var/lib/mysql \
       -e MYSQL_ROOT_PASSWORD=RootSuperSecretPassword \
       -e MYSQL_DATABASE=nextcloud -e MYSQL_USER=nextcloud \
       -e MYSQL_PASSWORD=UserSuperSecretPassword \
       mariadb:10
       
docker run -d --name nextcloud \
       --link db_nextcloud:db_nextcloud \
       -v /docker/nextcloud/data:/data \
       -v /docker/nextcloud/config:/config \
       -v /docker/nextcloud/apps:/apps2 \
       -v /docker/nextcloud/themes:/nextcloud/themes \
       -e UID=1000 -e GID=1000 \
       -e UPLOAD_MAX_SIZE=10G \
       -e APC_SHM_SIZE=128M \
       -e OPCACHE_MEM_SIZE=128 \
       -e CRON_PERIOD=15m \
       -e TZ=Etc/UTC \
       -e ADMIN_USER=Mr.Robot \
       -e ADMIN_PASSWORD=MySuperComplicatedPassword \
       -e DOMAIN=cloud.example.com \
       -e DB_TYPE=mysql \
       -e DB_NAME=nextcloud \
       -e DB_USER=nextcloud \
       -e DB_PASSWORD=UserSuperSecretPassword \
       -e DB_HOST=db_nextcloud \
       sckyzo/nextcloud:latest
```

You are **not obliged** to use `ADMIN_USER` and `ADMIN_PASSWORD`. If these variables are not provided, you'll be able to configure your admin acccount from your browser.

### Configure
In the admin panel, you should switch from `AJAX cron` to `cron` (system cron).

### Docker-compose
I advise you to use [docker-compose](https://docs.docker.com/compose/), which is a great tool for managing containers. You can create a `docker-compose.yml` with the following content (which must be adapted to your needs) and then run `docker-compose up -d nextcloud-db`, wait some 15 seconds for the database to come up, then run everything with `docker-compose up -d`, that's it! On subsequent runs,  a single `docker-compose up -d` is sufficient!

#### Docker-compose file
Don't copy/paste without thinking! It is a model so you can see how to do it correctly.

**This docker-compose file work with [my traefik v1.7 container](https://github.com/SckyzO/containers/tree/master/traefik)** (do not work with traefik v2)

My `/etc/environment` file
```
##########################
# DOCKER GENERAL SETTING #
##########################
PUID=1000
PGID=998
TZ=Europe/Paris
USERDIR=/home/user
DOMAINNAME=example.com

#########
# MYSQL #
#########
MYSQL_ROOT_PASSWORD="RootSuperSecretPassword"

#############
# NEXTCLOUD #
#############
MYSQL_NEXTCLOUD_USER="nextcloud"
MYSQL_NEXTCLOUD_PASSWORD="UserSuperSecretPassword"
MYSQL_NEXTCLOUD_DB="nextcloud"

```
My `docker-compose.yml` file

```
version: "3.6"
services:

# NEXTCLOUD
  nextcloud:
    hostname: nextcloud
    container_name: nextcloud
    image: sckyzo/nextcloud:latest
    restart: unless-stopped
    depends_on:
      - nextcloud-db
      - nextcloud-redis
    networks:
      - traefik_proxy
    environment:
      - UID=${PUID}
      - GID=${PGID}
      - UPLOAD_MAX_SIZE=10G
      - APC_SHM_SIZE=128M
      - OPCACHE_MEM_SIZE=128
      - CRON_PERIOD=15m
      - TZ=Europe/Paris
      - DOMAIN=localhost
      - DB_TYPE=mysql
      - DB_NAME=${MYSQL_NEXTCLOUD_DB}
      - DB_USER=${MYSQL_NEXTCLOUD_USER}
      - DB_PASSWORD=${MYSQL_NEXTCLOUD_PASSWORD}
      - DB_HOST=nextcloud-db
    volumes:
      - ${USERDIR}/docker/nextcloud/data:/data
      - ${USERDIR}/docker/nextcloud/config:/config
      - ${USERDIR}/docker/nextcloud/apps:/apps2
      - ${USERDIR}/docker/nextcloud/themes:/nextcloud/themes
    healthcheck:
      test: ["CMD", "curl", "-f", "http://127.0.0.1:8888"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 1m
    labels:
      - "traefik.enable=true"
      - "traefik.backend=my-cloud"
      - "traefik.frontend.rule=Host:nextcloud.${DOMAINNAME}"
      - "traefik.port=8888"
      - "traefik.docker.network=traefik_proxy"
      - "traefik.frontend.headers.SSLRedirect=true"
      - "traefik.frontend.headers.STSSeconds=315360000"
      - "traefik.frontend.headers.browserXSSFilter=true"
      - "traefik.frontend.headers.contentTypeNosniff=true"
      - "traefik.frontend.headers.forceSTSHeader=true"
      - "traefik.frontend.headers.SSLHost=${DOMAINNAME}"
      - "traefik.frontend.headers.STSIncludeSubdomains=true"
      - "traefik.frontend.headers.STSPreload=true"
      - "traefik.frontend.headers.frameDeny=true"
      - "traefik.frontend.headers.customFrameOptionsValue=SAMEORIGIN"
      - "traefik.frontend.redirect.permanent=true"
      - "traefik.frontend.redirect.regex=https://(.*)/.well-known/(card|cal)dav"
      - "traefik.frontend.redirect.replacement=https://$$1/remote.php/dav/"

# MYSQL
  nextcloud-db:
    hostname: nextcloud-db
    container_name: nextcloud-db
    image: mariadb:10
    restart: unless-stopped
      test: ["CMD", "curl", "-f", "http://127.0.0.1:3306"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 1m
    volumes:
      - ${USERDIR}/docker/nextcloud/db:/var/lib/mysql
    environment:
      - MYSQL_DATABASE=${MYSQL_NEXTCLOUD_DB}
      - MYSQL_USER=${MYSQL_NEXTCLOUD_USER}
      - MYSQL_PASSWORD=${MYSQL_NEXTCLOUD_PASSWORD}
      - MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
    networks:
      - traefik_proxy

# Redis
  nextcloud-redis:
    container_name: nextcloud-redis
    image: redis:alpine
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://127.0.0.1:6379"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 1m
    volumes:
      - ${USERDIR}/docker/nextcloud/redis:/data
    networks:
      - traefik_proxy


###########
# NETWORK #
###########
networks:
  traefik_proxy:
    external:
      name: traefik_proxy
  default:
    driver: bridge
```

You can update everything with `docker-compose pull` followed by `docker-compose up -d`.

### How to configure Redis
Redis can be used for distributed and file locking cache, alongside with APCu (local cache), thus making Nextcloud even more faster. As PHP redis extension is already included, all you have to is to deploy a redis server (you can do as above with docker-compose) and bind it to nextcloud in your config.php file :

```
'memcache.distributed' => '\OC\Memcache\Redis',
'memcache.locking' => '\OC\Memcache\Redis',
'memcache.local' => '\OC\Memcache\APCu',
'redis' => array(
   'host' => 'nextcloud-redis',
   'port' => 6379,
   ),
```

### Tip : how to use occ command
There is a script for that, so you shouldn't bother to log into the container, set the right permissions, and so on. Just use `docker exec -ti nexcloud occ command`.

### Reverse proxy
Of course you can use your own software! nginx, Haproxy, Caddy, h2o, Traefik...
The latter is especially a good choice when using Docker. [Give it a try!](https://traefik.io/)

Whatever your choice is, you have to know that headers are already sent by the container, including HSTS, so there's no need to add them again. **It is strongly recommended (I'd like to say : MANDATORY) to use Nextcloud through an encrypted connection (HTTPS).** [Let's Encrypt](https://letsencrypt.org/) provides free SSL/TLS certificates, so you have no excuses.


