ARG PHP_VERSION

FROM golang:1.18.2 AS gcsfuse
RUN apt update -y && apt install git
ENV GOPATH /go
RUN go install github.com/googlecloudplatform/gcsfuse@latest

FROM php:${PHP_VERSION}-fpm

COPY --from=gcsfuse /go/bin/gcsfuse /usr/local/bin

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
ENV ACCEPT_EULA Y
ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /tmp

RUN apt-get update -y && apt-get install -y \
      apt-transport-https \
      apt-utils \
      apt-utils \
      awscli \
      bash-completion \
      cron \
      curl \
      default-mysql-client \
      g++ \
      gcc \
      git \
      gnupg \
      gvfs \
      icu-devtools \
      imagemagick \
      lcov \
      libcairo2 \
      libcairo2-dev \
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
      libpng-dev \
      libsodium-dev \
      libxi6 \
      libxml2-dev \
      libyaml-dev \
      libzip-dev \
      libzookeeper-mt-dev \
      libzookeeper-mt2 \
      locales \
      nfs-common \
      odbcinst \
      pcscd \
      procps \
      procps \
      pv \
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
    && rm -rf /var/lib/apt/lists/* \
    && printf "\n\nexport COMPOSER_ALLOW_SUPERUSER=1\n" >> $HOME/.bash_profile 


ENV LD_PRELOAD /usr/lib/preloadable_libiconv.so php

RUN docker-php-ext-install -j$(nproc) intl \
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
    && docker-php-ext-install uploadprogress

COPY php/overrides.ini /usr/local/etc/php-fpm.d
COPY php/php.ini /usr/local/etc/php
COPY php/overrides.ini /usr/local/etc/php/conf.d

RUN pecl config-set php_ini /usr/local/etc/php/php.ini  \
    && pear config-set php_ini /usr/local/etc/php/php.ini  \
    && pecl channel-update pecl.php.net \
    && docker-php-ext-configure gd --with-freetype=/usr/include/ --with-jpeg=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install oauth \
    && mkdir -p /opt

RUN wget https://curl.se/ca/cacert.pem -O /etc/ssl/certs/cacert.pem

WORKDIR /opt

RUN echo "env[LC_ALL] = \$LC_ALL" >> /usr/local/etc/php-fpm.d/www.conf \
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
    && echo "export LANGUAGE=en_US.UTF-8" >> ~/.bashrc

COPY init /opt/init
COPY drush /root/.drush
RUN chmod +x /opt/init
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh
RUN echo "*/15 * * * *	root    cd /var/www && vendor/bin/drush core:cron 2>&1" >> /etc/crontab

RUN rm -Rf /usr/src/*
RUN echo "pm.status_path = /status\n" >> /usr/local/etc/php-fpm.conf
RUN wget -O /usr/local/bin/php-fpm-healthcheck \
    https://raw.githubusercontent.com/renatomefi/php-fpm-healthcheck/master/php-fpm-healthcheck \
    && chmod +x /usr/local/bin/php-fpm-healthcheck

STOPSIGNAL SIGQUIT

WORKDIR /var/www

EXPOSE 9000
ENTRYPOINT [ "/docker-entrypoint.sh"]
CMD [ "php-fpm" ]
