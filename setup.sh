#!/bin/sh

#########################################################
# Install Ruby & OpenStudio
#########################################################
echo "-----------------------------------"
echo "Installing Dependencies"
echo "-----------------------------------"
sudo apt-get update &&  sudo apt-get install -y ca-certificates curl gdebi-core git libglu1 libjpeg8 libfreetype6 libxi6 wget vim nano \
    build-essential libssl-dev libreadline-dev zlib1g-dev libsqlite3-dev libxml2-dev libxslt-dev libdbus-glib-1-2 libfontconfig1 libsm6 sudo

# Build and install Ruby 2.0 using rbenv for flexibility
echo "-----------------------------------"
echo "Installing Ruby"
echo "-----------------------------------"
cd ~/
git clone https://github.com/sstephenson/rbenv.git ~/.rbenv
git clone https://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build
`RUBY_CONFIGURE_OPTS=--enable-shared ~/.rbenv/bin/rbenv install 2.7.2`
~/.rbenv/bin/rbenv global 2.7.2
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc

# Add bundler gem
~/.rbenv/shims/gem install bundler


# Download Opentstudio
echo "-----------------------------------"
echo "Installing OpenStudio"
echo "-----------------------------------"
wget https://github.com/NREL/OpenStudio/releases/download/v3.3.0/OpenStudio-3.3.0+ad235ff36e-Ubuntu-20.04.deb -O OpenStudio.deb

# Install OpenStudio and clean it up
sudo dpkg -i OpenStudio.deb
rm OpenStudio.deb

cd /data/github/koritsu-www/app/Containers/Ruby/
~/.rbenv/shims/gem install bundler

cd /home/ubuntu/.rbenv/versions/2.7.2/lib/ruby/site_ruby
echo "require '/usr/local/openstudio-3.3.0/Ruby/openstudio.rb'" > openstudio.rb


#########################################################
# Install php
#########################################################
echo "-----------------------------------"
echo "Installing PHP"
echo "-----------------------------------"
DEBIAN_FRONTEND=noninteractive
sudo apt-get update && sudo apt-get install php php-common php-xml php-mysql php-gd php-opcache php-mbstring php-tokenizer php-json php-bcmath php-zip  php-pgsql  php-curl php-intl unzip zip -y
sudo curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer


#########################################################
# Install apache2 - Sudo
#########################################################
echo "-----------------------------------"
echo "Installing Apache"
echo "-----------------------------------"
sudo apt-get install apache2 -y
sudo a2enmod rewrite
sudo apt-get install libapache2-mod-php -y
sudo apt-get install -y apache2-utils
echo "ServerName localhost" | sudo tee -a /etc/apache2/apache2.conf
cd /data/github/koritsu-www
sudo cp vhost.conf /etc/apache2/sites-available/000-default.conf
echo "www-data ALL=(ALL) NOPASSWD:SETENV:/home/ubuntu/.rbenv/shims/ruby" |  sudo tee -a /etc/sudoers.d/002_second


#########################################################
# RUN Composer
#########################################################
echo "-----------------------------------"
echo "Run Composer Install"
echo "-----------------------------------"
cd /data/github/koritsu-www
composer update -n
composer install -n
cp .env.ubuntu .env


#########################################################
# Permissions
#########################################################
# Copy Current Directory
echo "-----------------------------------"
echo "Changing Permissions"
echo "-----------------------------------"
sudo usermod -a -G www-data ubuntu
cd /data/github/koritsu-www
sudo chmod 777 -R /data/github/koritsu-www/storage


#########################################################
# RUN Composer
#########################################################
echo "-----------------------------------"
echo "Key Generating"
echo "-----------------------------------"
php artisan key:generate


#########################################################
# Install Nodejs
#########################################################
echo "-----------------------------------"
echo "Install Nodejs"
echo "-----------------------------------"
sudo curl -sL https://deb.nodesource.com/setup_16.x | sudo -E bash -
sudo apt-get install -y nodejs

cd /data/github/koritsu-www/app/Containers/Koritsu/WebApp/UI/WEB/Views
npm install
cd /data/github/koritsu-www
npm install


#########################################################
# Install GEMS
#########################################################
echo "-----------------------------------"
echo "Install Gems for Koritsu"
echo "-----------------------------------"
cd '/data/github/koritsu-www/app/Containers/Ruby'
~/.rbenv/shims/bundle install --gemfile='/data/github/koritsu-www/app/Containers/Ruby/Gemfile'
~/.rbenv/shims/gem install rubyzip


#########################################################
# Install OpenStudio Server for Meta
#########################################################
echo "-----------------------------------"
echo "Install Gems for Open Studio"
echo "-----------------------------------"
cd '/data/github/'
wget https://github.com/NREL/OpenStudio-server/archive/refs/tags/v3.3.0.tar.gz
tar -xf v3.3.0.tar.gz
cd '/data/github/OpenStudio-server-3.3.0'
sudo ~/.rbenv/shims/ruby /data/github/OpenStudio-server-3.3.0/bin/openstudio_meta install_gems


#########################################################
# Install PSQL
#########################################################
echo "-----------------------------------"
echo "Install PostgreSQL"
echo "-----------------------------------"
sudo apt-get install postgresql postgresql-contrib -y


#########################################################
# Cleanup and run final tasks
#########################################################
echo "-----------------------------------"
echo "Cleanup"
echo "-----------------------------------"
sudo apt-get clean
sed -i 's/\r$//' /data/github/koritsu-www/startup.sh
chmod +x /data/github/koritsu-www/startup.sh
sudo chown -R www-data:www-data /data/github/koritsu-www
sudo service apache2  restart
