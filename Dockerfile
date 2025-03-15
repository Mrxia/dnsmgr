FROM alpine:3.19.7

# 设置工作目录
WORKDIR /app/www

RUN apk add --no-cache bash curl nginx php82 php82-ctype php82-curl php82-dom php82-fileinfo php82-fpm php82-ftp php82-gd php82-gettext php82-intl php82-iconv php82-mbstring php82-mysqli php82-opcache php82-openssl php82-phar php82-sodium php82-session php82-simplexml php82-tokenizer php82-xml php82-xmlreader php82-xmlwriter php82-zip php82-pdo php82-pdo_mysql php82-pdo_sqlite php82-pecl-swoole php82-pecl-ssh2 supervisor

RUN rm -rf /var/cache/apk/* /tmp/*

COPY configs/config/nginx.conf /etc/nginx/nginx.conf

ENV PHP_INI_DIR=/etc/php82

COPY configs/config/fpm-pool.conf /etc/php82/php-fpm.d/www.conf
COPY configs/config/php.ini /etc/php82/conf.d/custom.ini
COPY configs/config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN mkdir -p /usr/src && wget --no-cache https://github.com/netcccyun/dnsmgr/archive/refs/heads/main.zip -O /usr/src/www.zip && unzip /usr/src/www.zip -d /usr/src/ && mv /usr/src/dnsmgr-main /usr/src/www && rm -f /usr/src/www.zip

RUN wget https://mirrors.aliyun.com/composer/composer.phar -O /usr/local/bin/composer && chmod +x /usr/local/bin/composer

RUN composer install -d /usr/src/www --no-interaction --no-dev --optimize-autoloader

RUN adduser -D -s /sbin/nologin -g www www && chown -R www.www /usr/src/www /var/lib/nginx /var/log/nginx

RUN echo "*/15 * * * * cd /app/www && /usr/bin/php82 think opiptask" | crontab -u www -

RUN echo "* * * * * cd /app/www && /usr/bin/php82 think certtask" | crontab -u www -

COPY configs/config/run_tasks.sh /app/run_tasks.sh

RUN chmod +x /app/run_tasks.sh

COPY configs/config/entrypoint.sh /entrypoint.sh

ENTRYPOINT ["sh" "/entrypoint.sh"]

EXPOSE 80/tcp

CMD /usr/sbin/crond && /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf

HEALTHCHECK CMD curl --silent --fail http://127.0.0.1/fpm-ping || exit 1
