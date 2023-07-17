# Используйте образ PHP с поддержкой Composer
FROM php:8.1-fpm

# Установите основные зависимости
RUN apt-get update && apt-get install -y \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip
# Установите расширения PHP
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd

# Установите Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Установите Node.js и npm
RUN curl -sL https://deb.nodesource.com/setup_14.x | bash -
RUN apt-get install -y nodejs

# Установите глобальные зависимости Vue CLI
RUN npm install -g @vue/cli

# Установите рабочую директорию
WORKDIR /var/www

# Копируйте зависимости composer и package.json
COPY composer.json composer.lock ./
COPY package.json package-lock.json ./

# Установите зависимости composer
RUN composer install --no-scripts --no-autoloader

# Установите зависимости npm
RUN npm install

# Скопируйте все файлы проекта
COPY . .

# Установите разрешения на запись для директории хранилища Laravel
RUN chown -R www-data:www-data storage

# Сгенерируйте ключ приложения Laravel
RUN php artisan key:generate

RUN sleep 10
# ... предыдущие инструкции Dockerfile ...

# Добавьте скрипт для проверки готовности базы данных MySQL
COPY wait-for.sh /wait-for.sh
RUN chmod +x /wait-for.sh

CMD /wait-for.sh db:3306 --timeout=60 -- php artisan migrate:refresh

# Установите правильные разрешения на директории после миграции
RUN chown -R www-data:www-data storage

# Запустите веб-сервер PHP
CMD php artisan serve --host=0.0.0.0 --port=8000

# Откройте порт контейнера
EXPOSE 8000
