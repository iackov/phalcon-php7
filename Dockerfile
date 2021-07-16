FROM ubuntu:xenial-20210114
MAINTAINER Jack J

ENV DEBIAN_FRONTEND noninteractive

# Timezone
ENV TIMEZONE Asia/Yekaterinburg
ENV PHP_MEMORY_LIMIT 1024M
ENV MAX_UPLOAD 128M
ENV PHP_MAX_FILE_UPLOAD 128
ENV PHP_MAX_POST 128M

RUN PACKAGES_TO_INSTALL="sudo git cron php7.0-dev composer php-xdebug php7.0-mbstring php7.0-curl php7.0-fpm nginx supervisor php7.0-mysql php7.0-phalcon php-amqp php7.0-bcmath php7.0-gd php-igbinary php-memcached php-mongodb php-msgpack php-redis php7.0-soap php7.0-xml" && \
    apt-get update && \
    apt-get install -y software-properties-common && \
    apt-get install -y language-pack-en-base && \
    apt-add-repository -y ppa:phalcon/stable && \
    LC_ALL=en_US.UTF-8 apt-add-repository -y ppa:ondrej/php && \
    apt-get update && \
    apt-get install -y $PACKAGES_TO_INSTALL && \
    apt-get autoremove -y && \
    apt-get clean && \
    apt-get autoclean

#RUN pecl install yaml-beta && \
#    echo 'extension=yaml.so' > /etc/php/7.0/mods-available/yaml.ini && \
#    ln -s /etc/php/7.0/mods-available/yaml.ini /etc/php/7.0/cli/conf.d/50-yaml.ini && \
#    ln -s /etc/php/7.0/mods-available/yaml.ini /etc/php/7.0/fpm/conf.d/50-yaml.ini

RUN echo 'extension=phalcon.so' > /etc/php/7.0/mods-available/phalcon.ini && \
    ln -s /etc/php/7.0/mods-available/phalcon.ini /etc/php/7.0/cli/conf.d/50-phalcon.ini && \
    ln -s /etc/php/7.0/mods-available/phalcon.ini /etc/php/7.0/fpm/conf.d/50-phalcon.ini

# configure NGINX as non-daemon
RUN echo "daemon off;" >> /etc/nginx/nginx.conf

# configure php-fpm as non-daemon
RUN sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/7.0/fpm/php-fpm.conf

# configure PHP
RUN set -ex \
    && sed -i "s|;date.timezone =.*|date.timezone = ${TIMEZONE}|" /etc/php/7.0/fpm/php.ini \
    && sed -i "s|;date.timezone =.*|date.timezone = ${TIMEZONE}|" /etc/php/7.0/cli/php.ini \
    && sed -i "s|memory_limit =.*|memory_limit = ${PHP_MEMORY_LIMIT}|" /etc/php/7.0/fpm/php.ini \
    && sed -i "s|upload_max_filesize =.*|upload_max_filesize = ${MAX_UPLOAD}|" /etc/php/7.0/fpm/php.ini \
    && sed -i "s|max_file_uploads =.*|max_file_uploads = ${PHP_MAX_FILE_UPLOAD}|" /etc/php/7.0/fpm/php.ini \
    && sed -i "s|post_max_size =.*|post_max_size = ${PHP_MAX_POST}|" /etc/php/7.0/fpm/php.ini \
    && sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/7.0/fpm/php.ini

# clear apt cache and remove unnecessary packages
RUN apt-get autoclean && apt-get -y autoremove

# add a phpinfo script for INFO purposes
RUN echo "<?php phpinfo();" >> /var/www/html/index.php

# NGINX mountable directories for config and logs
VOLUME ["/etc/nginx/sites-enabled", "/etc/nginx/certs", "/etc/nginx/conf.d", "/var/log/nginx"]

# NGINX mountable directory for apps
VOLUME ["/var/www"]

# copy config file for Supervisor
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# backup default default config for NGINX
RUN mv /etc/nginx/sites-available/default /etc/nginx/sites-available/default.bak

# copy local defualt config file for NGINX
COPY nginx-site.conf /etc/nginx/sites-available/default

# php7.0-fpm will not start if this directory does not exist
RUN mkdir /run/php

# NGINX ports
EXPOSE 80 443

CMD ["/usr/bin/supervisord"]
