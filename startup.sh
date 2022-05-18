#!/bin/sh

if [ -f '.env' ]
then
  export $(cat .env | xargs)
fi

CONTAINER_ALREADY_STARTED="CONTAINER_ALREADY_STARTED_PLACEHOLDER"
HAS_MIGRATED=`psql postgresql://$DB_USERNAME:$DB_PASSWORD@$DB_HOST:$DB_PORT/$DB_DATABASE -tAc 'SELECT * FROM oauth_clients;' | sed -n '1 p' | sed 's/|/ /'| awk '{print $1}'`

echo "\n\n-- Checking if Database Has Migrated--"
echo "Status: "
echo $HAS_MIGRATED
echo "\n"

if  [ ! -e $CONTAINER_ALREADY_STARTED ] &&  [ -z "$HAS_MIGRATED" ]; then
    touch $CONTAINER_ALREADY_STARTED

	sleep 30
    echo "\n\n-- Migrating Database --"

    php /data/github/koritsu-www/artisan migrate:fresh
    php /data/github/koritsu-www/artisan db:seed
    php /data/github/koritsu-www/artisan apiato:permissions:toRole admin
    php /data/github/koritsu-www/artisan optimize
    php /data/github/koritsu-www/artisan config:clear

    echo "\n\n-- Inserting new web key --"
    KEY=`php /data/github/koritsu-www/artisan passport:client --password --public --name=WEB --provider=users | tail -1 | cut -d ":" -f2 | awk '{$1=$1};1'`
    echo $KEY
	sudo sed -i "s/MIX_VUE_APP_CLIENT_SECRET_VALUE/$KEY/" /data/github/koritsu-www/.env
	sudo php /data/github/koritsu-www/artisan passport:install

else
	echo "\n\n-- Database already migrated"
	echo "\n\n-- Inserting existing web key --"
	KEY=`psql postgresql://$DB_USERNAME:$DB_PASSWORD@$DB_HOST:$DB_PORT/$DB_DATABASE -tAc 'SELECT Secret FROM oauth_clients WHERE id=1;' | sed -n '1 p' | sed 's/|/ /'| awk '{print $1}'`

	echo $KEY
	sudo sed -i "s/MIX_VUE_APP_CLIENT_SECRET_VALUE/$KEY/" /data/github/koritsu-www/.env
fi

echo "\n\n-- NPM Run Dev/Prod --"
cd '/data/github/koritsu-www'
npm run dev
#npm run prod

echo "\n\n-- Generating API Documentation --"
sudo php /data/github/koritsu-www/artisan apiato:apidoc

#echo "\n\n-- Starting Open Studio Server --"
#/data/github/OpenStudio-server-3.1.0-2/bin/openstudio_meta start_local /data/oss/

echo "\n\n-- Starting Queue --"
sudo chmod 777 -R /data/github/koritsu-www/storage/framework/cache/data
sudo php /data/github/koritsu-www/artisan queue:work &
