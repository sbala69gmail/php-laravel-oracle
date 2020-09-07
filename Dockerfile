FROM php:7.3-fpm-alpine

#old port change new port =>  RUN sed -i 's/9000/9001/' /usr/local/etc/php-fpm.d/zz-docker.conf
RUN sed -i 's/9000/9000/' /usr/local/etc/php-fpm.d/zz-docker.conf

# Install dev dependencies
RUN apk add --no-cache --virtual .build-deps \
    $PHPIZE_DEPS \
    curl-dev \
    imagemagick-dev \
    libtool \
    libxml2-dev \
    postgresql-dev \
    sqlite-dev

# Install production dependencies
RUN apk add --no-cache \
    bash \
    curl \
    g++ \
    gcc \
    git \
    imagemagick \
    libc-dev \
    libpng-dev \
    make \
    mysql-client \
    nodejs \
    nodejs-npm \
    yarn \
    openssh-client \
    postgresql-libs \
    rsync \
    zlib-dev \
    libzip-dev \
    unzip \
    libaio

# Install PECL and PEAR extensions
RUN pecl install \
    imagick \
    xdebug \
    mongodb

# create .ini file
RUN echo "extension=mongodb.so" >> /usr/local/etc/php/conf.d/mongodb.ini

# Install and enable php extensions
RUN docker-php-ext-enable \
    imagick \
    xdebug
RUN docker-php-ext-configure zip --with-libzip
RUN docker-php-ext-install \
    curl \
    iconv \
    mbstring \
    pdo \
    pdo_mysql \
    pdo_pgsql \
    pdo_sqlite \
    pcntl \
    tokenizer \
    xml \
    gd \
    zip \
    bcmath

# Oracle instantclient
ENV LD_LIBRARY_PATH /usr/local/instantclient
ENV ORACLE_HOME /usr/local/instantclient

# Install Oracle Client and build OCI8 (Oracle Command Interface 8 - PHP extension)

RUN apk add php7-pear php7-dev gcc musl-dev libnsl libaio &&\
## Download and unarchive Instant Client v11
  curl -o /tmp/basic.zip https://raw.githubusercontent.com/bumpx/oracle-instantclient/master/instantclient-basic-linux.x64-11.2.0.4.0.zip && \
  curl -o /tmp/sdk.zip https://raw.githubusercontent.com/bumpx/oracle-instantclient/master/instantclient-sdk-linux.x64-11.2.0.4.0.zip && \
  curl -o /tmp/sqlplus.zip https://raw.githubusercontent.com/bumpx/oracle-instantclient/master/instantclient-sqlplus-linux.x64-11.2.0.4.0.zip && \
  unzip -d /usr/local/ /tmp/basic.zip && \
  unzip -d /usr/local/ /tmp/sdk.zip && \
  unzip -d /usr/local/ /tmp/sqlplus.zip && \
## Links are required for older SDKs
  ln -s /usr/local/instantclient_11_2 ${ORACLE_HOME} && \
  ln -s ${ORACLE_HOME}/libclntsh.so.* ${ORACLE_HOME}/libclntsh.so && \
  ln -s ${ORACLE_HOME}/libocci.so.* ${ORACLE_HOME}/libocci.so && \
  ln -s ${ORACLE_HOME}/lib* /usr/lib && \
  ln -s ${ORACLE_HOME}/sqlplus /usr/bin/sqlplus &&\
  ln -s /usr/lib/libnsl.so.2.0.0  /usr/lib/libnsl.so.1 &&\
## Build OCI8 with PECL
  echo "instantclient,${ORACLE_HOME}" | pecl install oci8 &&\
  echo 'extension=oci8.so' > /etc/php7/conf.d/30-oci8.ini &&\
#  Clean up
  apk del php7-pear php7-dev gcc musl-dev &&\
  rm -rf /tmp/*.zip /var/cache/apk/* /tmp/pear/

RUN docker-php-ext-configure oci8 --with-oci8=instantclient,$ORACLE_HOME && docker-php-ext-install oci8


# Install composer
ENV COMPOSER_HOME /composer
ENV PATH ./vendor/bin:/composer/vendor/bin:$PATH
ENV COMPOSER_ALLOW_SUPERUSER 1
RUN curl -s https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin/ --filename=composer

# Install PHP_CodeSniffer
RUN composer global require "squizlabs/php_codesniffer=*"

# Cleanup dev dependencies
RUN apk del -f .build-deps

# Setup working directory
WORKDIR /var/www
