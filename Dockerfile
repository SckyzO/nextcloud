FROM sckyzo/nginx-php:7.3

ARG NEXTCLOUD_VERSION=18.0.4
ARG GPG_nextcloud="2880 6A87 8AE4 23A2 8372  792E D758 99B9 A724 937A"

ENV UID=1000 GID=998 \
    UPLOAD_MAX_SIZE=10G \
    APC_SHM_SIZE=128M \
    OPCACHE_MEM_SIZE=128 \
    MEMORY_LIMIT=512M \
    CRON_PERIOD=15m \
    CRON_MEMORY_LIMIT=1g \
    TZ=Europe/Paris \
    DB_TYPE=sqlite3 \
    DOMAIN=localhost

RUN apk -U upgrade \
 && apk add -t build-dependencies \
    gnupg \
    tar \
    oniguruma \
    oniguruma-dev \
    sqlite-libs \
    build-base \
    autoconf \
    automake \
    pcre-dev \
    libtool \
    samba-dev \
 && apk add \
    libressl \
    ca-certificates \
    libsmbclient \
    tzdata \
 && pecl channel-update pecl.php.net \
 && pecl install \
    smbclient \
    apcu \
    redis \
 && echo "extension=smbclient.so" > /php/conf.d/smbclient.ini \
 && echo "extension=redis.so" > /php/conf.d/redis.ini \
 && mkdir /nextcloud \
 && cd /tmp \
 && NEXTCLOUD_TARBALL="nextcloud-${NEXTCLOUD_VERSION}.tar.bz2" \
 && wget -q https://download.nextcloud.com/server/releases/${NEXTCLOUD_TARBALL} \
 && wget -q https://download.nextcloud.com/server/releases/${NEXTCLOUD_TARBALL}.sha512 \
 && wget -q https://download.nextcloud.com/server/releases/${NEXTCLOUD_TARBALL}.asc \
 && wget -q https://nextcloud.com/nextcloud.asc \
 && echo "Verifying both integrity and authenticity of ${NEXTCLOUD_TARBALL}..." \
 && CHECKSUM_STATE=$(echo -n $(sha512sum -c ${NEXTCLOUD_TARBALL}.sha512) | tail -c 2) \
 && if [ "${CHECKSUM_STATE}" != "OK" ]; then echo "Warning! Checksum does not match!" && exit 1; fi \
 && gpg --import nextcloud.asc \
 && FINGERPRINT="$(LANG=C gpg --verify ${NEXTCLOUD_TARBALL}.asc ${NEXTCLOUD_TARBALL} 2>&1 \
  | sed -n "s#Primary key fingerprint: \(.*\)#\1#p")" \
 && if [ -z "${FINGERPRINT}" ]; then echo "Warning! Invalid GPG signature!" && exit 1; fi \
 && if [ "${FINGERPRINT}" != "${GPG_nextcloud}" ]; then echo "Warning! Wrong GPG fingerprint!" && exit 1; fi \
 && echo "All seems good, now unpacking ${NEXTCLOUD_TARBALL}..." \
 && tar xjf ${NEXTCLOUD_TARBALL} --strip 1 -C /nextcloud \
 && update-ca-certificates \
 && apk del build-dependencies \
 && rm -rf /var/cache/apk/* /tmp/* /root/.gnupg

COPY rootfs /

RUN chmod +x /usr/local/bin/* /etc/s6.d/*/* /etc/s6.d/.s6-svscan/*

VOLUME /data /config /apps2 /nextcloud/themes

EXPOSE 8888

LABEL description="Nextcloud gives you access to all your files wherever you are. Nextcloud is server software for creating file hosting services" \
      nextcloud="Nextcloud v${NEXTCLOUD_VERSION}" \
      maintainer="SckyzO <https://www.github.com/sckyzo>"

CMD ["run.sh"]
