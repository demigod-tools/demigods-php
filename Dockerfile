ARG PHP_VERSION

FROM golang:1.18.2 AS gcsfuse
RUN apt update -y && apt install git
ENV GOPATH /go
RUN go install github.com/googlecloudplatform/gcsfuse@latest \
     && go install github.com/mikefarah/yq/v4@latest
FROM php:${PHP_VERSION}-fpm

COPY --from=gcsfuse /go/bin/gcsfuse /usr/local/bin
COPY --from=gcsfuse /go/bin/yq /usr/local/bin

LABEL org.label-schema.vendor="demigod-tools" \
  org.label-schema.name=$REPO_NAME \
  org.label-schema.description="Prettier is an opinionated code formatter." \
  org.label-schema.build-date=$BUILD_DATE \
  org.label-schema.version=$VERSION \
  org.label-schema.vcs-ref=$VCS_REF \
  org.label-schema.vcs-url="https://github.com/$REPO_NAME" \
  org.label-schema.usage="https://github.com/$REPO_NAME/blob/master/README.md#usage" \
  org.label-schema.schema-version="1.0"

ARG ENV
ENV COMPOSER_ALLOW_SUPERUSER 1
ENV LANG en_US.utf8
ENV DEBIAN_FRONTEND=noninteractive


COPY init /opt/init
COPY drush /root/.drush
COPY docker-entrypoint.sh /docker-entrypoint.sh

WORKDIR /tmp

RUN update-ca-certificates --verbose --fresh \
    && mkdir -p /usr/share/man/man1 \
    && apt-get update -y --fix-missing  \
    && apt-get upgrade  \
    && apt-get install -y \
      apt-transport-https \
      apt-utils \
      apt-utils \
      awscli \
      bash-completion \
      cron \
      curl \
      default-mysql-client \
      libfcgi0ldbl \
      g++ \
      gcc \
      git \
      gnupg \
      gvfs \
      icu-devtools \
      imagemagick \
      iputils-ping \
      jq \
      lcov \
      less  \
      libcairo2 \
      libcairo2-dev \
      libfreetype6  \
      libfreetype6-dev \
      libgconf-2-4 \
      libgd-dev \
      libgss3 \
      libicu-dev \
      libjpeg-dev \
      libjpeg62-turbo-dev \
      libmagickwand-dev \
      libpcre3-dev \
      libpng-dev \
      libsodium-dev \
      libtool \
      libtool-bin \
      libxext6  \
      libxi6 \
      libxml2-dev \
      libxrender1  \
      libxtst6  \
      libyaml-dev \
      libzip-dev \
      libzookeeper-mt-dev \
      libzookeeper-mt2 \
      locales \
      nfs-common \
      net-tools\
      odbcinst \
      pcscd \
      procps \
      procps \
      pv \
      python3 \
      python3-cryptography \
      python3-netifaces \
      python3-pip \
      re2c \
      redis-tools \
      rsync \
      software-properties-common \
      supervisor \
      syncthing \
      unixodbc \
      unixodbc-dev \
      unzip \
      vim \
      wget \
      xvfb \
      zip \
      zstd \
    && rm -rf /var/lib/apt/lists/* \
    && printf "\n\nexport COMPOSER_ALLOW_SUPERUSER=1\n" >> $HOME/.bash_profile \
    && chmod +x ~/.* \
    && echo "en_US.UTF-8 UTF-8" > /etc/locale.gen \
    && locale-gen en_US.UTF-8 \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 \
    && docker-php-ext-install -j$(nproc) intl \
    && docker-php-ext-install -j$(nproc) pcntl \
    && docker-php-ext-install -j$(nproc) soap \
    && docker-php-ext-install -j$(nproc) xml \
    && docker-php-ext-install -j$(nproc) zip \
    && docker-php-ext-install -j$(nproc) pdo \
    && docker-php-ext-install -j$(nproc) pdo_mysql \
    && docker-php-ext-install -j$(nproc) opcache \
    && pecl bundle -d /usr/src/php/ext zstd \
    && cd /usr/src/php/ext/zstd \
    && phpize && ./configure && make \
    && echo "OAUTH ===>\n" \
    && pecl bundle -d /usr/src/php/ext oauth \
    && cd /usr/src/php/ext/oauth \
    && phpize && ./configure && make \
    && pecl bundle -d /usr/src/php/ext imagick \
    && cd /usr/src/php/ext/imagick \
    && phpize && ./configure && make \
    && docker-php-ext-install imagick \
    && pecl bundle -d /usr/src/php/ext zookeeper-1.0.0 \
    && cd /usr/src/php/ext/zookeeper \
    && phpize && ./configure && make \
    && docker-php-ext-install zookeeper \
    && pecl bundle -d /usr/src/php/ext yaml \
    && rm /usr/src/php/ext/yaml-*.tgz \
    && docker-php-ext-install yaml \
    && pecl bundle -d /usr/src/php/ext redis \
    && rm /usr/src/php/ext/redis-*.tgz \
    && docker-php-ext-install redis \
    && pecl bundle -d /usr/src/php/ext pcov \
    && rm /usr/src/php/ext/pcov-*.tgz \
    && docker-php-ext-install pcov \
    && pecl bundle -d /usr/src/php/ext uploadprogress \
    && rm /usr/src/php/ext/uploadprogress-*.tgz \
    && docker-php-ext-install uploadprogress \
    && pecl config-set php_ini /usr/local/etc/php/php.ini  \
    && pear config-set php_ini /usr/local/etc/php/php.ini  \
    && pecl channel-update pecl.php.net \
    && docker-php-ext-configure gd --with-freetype=/usr/include/ --with-jpeg=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install oauth \
    && mkdir -p /opt \
    && echo "env[LC_ALL] = \$LC_ALL" >> /usr/local/etc/php-fpm.d/www.conf \
    && echo "env[ENV] = \$ENV" >> /usr/local/etc/php-fpm.d/www.conf \
    && echo "env[DB_DRIVER] = \$DB_DRIVER" >> /usr/local/etc/php-fpm.d/www.conf \
    && echo "env[DB_HOST] = \$DB_HOST" >> /usr/local/etc/php-fpm.d/www.conf \
    && echo "env[DB_NAME] = \$DB_NAME" >> /usr/local/etc/php-fpm.d/www.conf \
    && echo "env[DB_USER] = \$DB_USER" >> /usr/local/etc/php-fpm.d/www.conf \
    && echo "env[DB_PASSWORD] = \$DB_PASSWORD" >> /usr/local/etc/php-fpm.d/www.conf \
    && echo "env[DB_PORT] = \$DB_PORT" >> /usr/local/etc/php-fpm.d/www.conf \
    && echo "env[DRUPAL_HASH_SALT] = \$DRUPAL_HASH_SALT" >> /usr/local/etc/php-fpm.d/www.conf \
    && echo "env[CACHE_HOST] = \$CACHE_HOST" >> /usr/local/etc/php-fpm.d/www.conf \
    && echo "env[CACHE_PORT] = \$CACHE_PORT" >> /usr/local/etc/php-fpm.d/www.conf \
    && echo "env[DRUSH_OPTIONS_URI] = \$DRUSH_OPTIONS_URI" >> /usr/local/etc/php-fpm.d/www.conf \
    && echo "env[PHP_IDE_CONFIG] = \$PHP_IDE_CONFIG" >> /usr/local/etc/php-fpm.d/www.conf \
    && echo "env[DRUPAL_SYSTEM_LOGGING_ERROR_LEVEL] = \$DRUPAL_SYSTEM_LOGGING_ERROR_LEVEL" >> /usr/local/etc/php-fpm.d/www.conf \
    && echo "opcache.enable=1" >>  /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini \
    && echo "opcache.jit_buffer_size=100M" >> /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini \
    && echo "opcache.jit=1255" >> /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini \
    && echo "export LC_ALL=en_US.UTF-8" >> ~/.bashrc \
    && echo "export LANG=en_US.UTF-8" >> ~/.bashrc \
    && echo "export LANGUAGE=en_US.UTF-8" >> ~/.bashrc \
    && chmod +x /opt/init && chmod +x /docker-entrypoint.sh \
    && echo "*/15 * * * *	root    cd /var/www && vendor/bin/drush core:cron 2>&1" >> /etc/crontab \
    && pip3 install projector-installer --user \
    && echo "pm.status_path = /status" >> /usr/local/etc/php-fpm.conf \
    && wget -O /usr/local/bin/php-fpm-healthcheck \
    https://raw.githubusercontent.com/renatomefi/php-fpm-healthcheck/master/php-fpm-healthcheck \
    && chmod +x /usr/local/bin/php-fpm-healthcheck \
    && chown -R www-data:www-data /var/www/web  \
    && rm -Rf /var/www/html  \
    && ln -s /var/www/web /var/www/html

#    && rm -Rf /usr/bin/iconv \
#    && curl -SL http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.14.tar.gz | tar -xz -C . \
#    && cd libiconv-1.14 \
#    && ./configure --prefix=/ \
#    && curl -SL https://raw.githubusercontent.com/mxe/mxe/7e231efd245996b886b501dad780761205ecf376/src/libiconv-1-fixes.patch \
#    | patch -p1 -u  \
#    && make \
#    && make install \
#    && libtool --finish /usr/local/lib \
#    && cd .. \
#    && rm -rf libiconv-1.14

COPY php /usr/local/etc


STOPSIGNAL SIGQUIT

WORKDIR /var/www

EXPOSE 9000
ENTRYPOINT [ "/docker-entrypoint.sh"]
CMD [ "php-fpm" ]
