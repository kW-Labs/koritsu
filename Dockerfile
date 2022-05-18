FROM ubuntu:20.10

#########################################################
# Install Ruby & Openstudio
#########################################################
# Install gdebi, which handles the installation of OpenStudio's dependencies including Qt5,
# Boost, and Ruby 2.7.2

RUN apt-get update && apt-get install -y ca-certificates curl gdebi-core git libglu1 libjpeg8 libfreetype6 libxi6 wget vim nano \
    build-essential libssl-dev libreadline-dev zlib1g-dev libsqlite3-dev libxml2-dev libxslt-dev libdbus-glib-1-2 libfontconfig1 libsm6 sudo

# Build and install Ruby 2.0 using rbenv for flexibility
RUN git clone https://github.com/sstephenson/rbenv.git ~/.rbenv
RUN git clone https://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build
RUN RUBY_CONFIGURE_OPTS=--enable-shared ~/.rbenv/bin/rbenv install 2.7.2
RUN ~/.rbenv/bin/rbenv global 2.7.2

RUN echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
RUN echo 'eval "$(rbenv init -)"' >> ~/.bashrc

# Add bundler gem
RUN ~/.rbenv/shims/gem install bundler

# Add RUBYLIB link for openstudio.rb
ENV RUBYLIB /usr/Ruby

# Download Opentstudio
RUN wget https://github.com/NREL/OpenStudio/releases/download/v3.3.0/OpenStudio-3.3.0+ad235ff36e-Ubuntu-20.04.deb -O OpenStudio.deb

# Instal OpenStudio and clean it up
RUN  dpkg -i OpenStudio.deb

WORKDIR /data/github/koritsu-www/app/Containers/Ruby/
RUN ~/.rbenv/shims/gem install bundler

WORKDIR /root/.rbenv/versions/2.7.2/lib/ruby/site_ruby
RUN echo "require '/usr/local/openstudio-3.3.0/Ruby/openstudio.rb'" > openstudio.rb


#########################################################
# Install php
#########################################################
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install php php-common php-xml php-mysql php-gd php-opcache php-mbstring php-tokenizer php-json php-bcmath php-zip  php-pgsql  php-curl php-intl unzip zip -y
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer


#########################################################
# Install apache2
#########################################################
RUN apt-get install apache2 -y
RUN a2enmod rewrite
RUN apt-get install libapache2-mod-php -y
RUN apt-get install -y apache2-utils
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf
COPY vhost.conf /etc/apache2/sites-available/000-default.conf
RUN echo "www-data ALL=(ALL) NOPASSWD:SETENV:/root/.rbenv/shims/ruby" > /etc/sudoers.d/002_second


#########################################################
# Copy Directory
#########################################################
# Copy Current Directory
# Note: Composer2: `composer install` was run prior to running this file.
WORKDIR /data/github/koritsu-www
COPY  . /data/github/koritsu-www
RUN mkdir /data/github/koritsu-www/storage/framework/cache/data
RUN chmod 777 -R /data/github/koritsu-www/storage
RUN chown -R www-data:www-data /data/github/koritsu-www


#########################################################
# RUN Composer
#########################################################
RUN composer install -n
RUN mv .env.docker .env
RUN php artisan key:generate


#########################################################
# Install Nodejs
#########################################################
RUN apt-get install nodejs npm -y
RUN npm install
WORKDIR /data/github/koritsu-www/app/Containers/Koritsu/WebApp/UI/WEB/Views
RUN npm install


#########################################################
# Install GEMS
#########################################################
WORKDIR '/data/github/koritsu-www/app/Containers/Ruby'
RUN ~/.rbenv/shims/bundle install --gemfile='/data/github/koritsu-www/app/Containers/Ruby/Gemfile'
RUN ~/.rbenv/shims/gem install rubyzip
# RUN ~/.rbenv/shims/gem install openstudio-analysis -v 1.1.0
# RUN ~/.rbenv/shims/gem install openstudio-common-measures -v 0.3.2 --no-ri --no-doc --verbose --debug


#########################################################
# Install OpenStudio Server for Meta
#########################################################
WORKDIR '/data/github/'
RUN wget https://github.com/NREL/OpenStudio-server/archive/refs/tags/v3.3.0.tar.gz
RUN tar -xf v3.3.0.tar.gz
# RUN sed -i "s/2.5.1/2.5.5/" /data/github/OpenStudio-server-3.1.0-2/.ruby-version
WORKDIR '/data/github/OpenStudio-server-3.3.0'
RUN ~/.rbenv/shims/bundle install
RUN ~/.rbenv/shims/ruby /data/github/OpenStudio-server-3.3.0/bin/openstudio_meta install_gems


#########################################################
# Install Openstudio-Sever Req
#########################################################
RUN wget -qO - https://www.mongodb.org/static/pgp/server-5.0.asc | sudo apt-key add -
RUN echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/5.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-5.0.list
RUN sudo apt-get update
RUN sudo apt-get install -y mongodb-org
RUN mkdir /data/oss
RUN chmod 777 -R /data/oss
RUN mkdir /data/oss/logs
RUN mkdir /data/oss/data
RUN mkdir /data/oss/data/db
RUN ln -s /root/.rbenv/shims/ruby /usr/bin/ruby


#########################################################
# Install PSQL
#########################################################
RUN apt-get install postgresql postgresql-contrib -y


#########################################################
# Cleanup and final tasks
#########################################################
RUN apt-get clean
EXPOSE 80 8080
WORKDIR '/data/github/koritsu-www/'
RUN sed -i 's/\r$//' /data/github/koritsu-www/startup.sh
RUN chmod +x /data/github/koritsu-www/startup.sh
ENTRYPOINT "/data/github/koritsu-www/startup.sh" &&   /usr/sbin/apache2ctl -D FOREGROUND
