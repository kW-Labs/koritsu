# Koritsu
Kōritsu is a tool that allows the generation of an energy model that represents the important first-order characteristics that impact a building’s energy use. This tool allows for high-level building energy insights in an easy-to-use package.

## Install Docker on your Operating System
https://docs.docker.com/compose/install/

## Create New Build
Navigate to this working directory and type the following

```
docker build -t koritsu-www:latest .
```

Note the included period after space


General build command:
```
docker build -t koritsu-www:TAG .
```
where 'TAG' is some identifier (for more see: https://docs.docker.com/engine/reference/commandline/tag/).


## Run Docker Composer to Start Container
Navigate to this working directory repo and type the following command:

```
docker-compose up -d
```

This will take about 15-30 minutes to run. The following containers will be built:
* Web & API container
	* Web URL: http://koritsu.test
		* Starts Queue in the background
		* Contains Ruby Gems to run analysis
		* Contains OpenStudio 3.1.0-2 and Gems to use Openstudio Meta
	* API Docs: http://koritsu.test/docs & ttp://koritsu.test/docs/private
	* Super Admin User / Password: admin@admin.com / admin
* Database container
	* PostgreSQL
* pgAdmin container
	* http://db.koritsu.test:8080/

Windows users need to install the WSL kernel update:
https://docs.microsoft.com/en-us/windows/wsl/install-win10#step-4---download-the-linux-kernel-update-package

Also windows users need to edit this hosts file:
```C:\Windows\System32\drivers\etc```

Edit the file like so:
```
127.0.0.1 koritsu.test
127.0.0.1 api.koritsu.test
```

Optional - Add the db url
```
127.0.0.1 db.koritsu.test
```

Wait about 1 minute after the container is **done** so the database can initialize and compile.


## Bash into Docker
You can use the UI to go into CLI but this is the preferred method. First find the Container ID by running the following command:

```
docker ps
```

Then use this line to run bash on that container:
```
docker exec -it <-Container-id-> bash
```

# Running Analysis via CLI
Here is how to run an analysis via CLI:
```
php artisan openstudio:base 1 true
```
1 is the project id and true is need if debugging.

To run debug mode in the ruby script add **true** to the command from the analysis debugging, like so:
```
cd /data/github/koritsu-www/app/Containers/Ruby; /root/.rbenv/shims/ruby /data/github/koritsu-www/app/Containers/Ruby/createAnalysis.rb '{"weather_file_name":"USA_UT_Salt.Lake.City.Intl.AP.725720_TMY3.epw","alternative_name":"Base","project_id":1,"project_name":"Docker Test","measures":[{"name":"openstudio_results","arguments":[]},{"name":"ChangeBuildingLocation","arguments":{"weather_file_name":"USA_UT_Salt.Lake.City.Intl.AP.725720_TMY3.epw","climate_zone":"ASHRAE 169-2013-4B"}},{"name":"create_bar_from_building_type_ratios","arguments":{"bldg_type_a":"SmallOffice","template":"90.1-2010","total_bldg_floor_area":55000,"floor_height":15,"num_stories_above_grade":2,"num_stories_below_grade":0,"building_rotation":12,"ns_to_ew_ratio":2,"wwr":0.35,"climate_zone":"ASHRAE 169-2013-4B"}},{"name":"create_typical_building_from_model","arguments":{"system_type":"VAV district chilled water with district hot water reheat","hvac_delivery_type":"Forced Air","htg_src":"NaturalGas","clg_src":"Electricity","swh_src":"Inferred","kitchen_makeup":"None","onsite_parking_fraction":0.25,"modify_wkdy_op_hrs":true,"wkdy_op_hrs_start_time":6,"wkdy_op_hrs_duration":10,"modify_wknd_op_hrs":true,"wknd_op_hrs_start_time":10,"wknd_op_hrs_duration":4,"unmet_hours_tolerance":2}}]}' /data/github/OpenStudio-server-3.1.0-2/bin/openstudio_meta 34.222.109.73 true
```

## Accessing the database
Use the pgAdmin web portal at

http://db.koritsu.test:8080/

You need to add a server. The server info is in the docker-compose.yml. The server host is 'db' but you might need to get the IP of the docker container by running the following command:

```
docker inspect <-Container-id->
```

## Stopping Docker
To stop all services run the following in the working directory repo.
```
docker-compose down
```

# Ubuntu Install
To Setup Koritsu on Ubuntu you need to following these two steps (1) Setup Step (2) Configure Postgreql (3) Update .env (4) Startup Steps

# Preparation
Make sure you have you Ubuntu instance setup with 8 Gb of ram and 2 CPU cores.  This will cost around $40 per month using AWS lightsail.
You need to connect to Ubuntu via SSH + your key. Once connected make sure Ubuntu is up to date. This project was tested on Ubuntu 20.

```
sudo apt-get update
sudo apt-get upgrade -y
```

## Step 1:  Setup
Create the following root folder:
```
sudo mkdir /data
sudo chmod 777 -R /data
```
Create a github folder underneath and clone this repo
```
mkdir /data/github
```


### Github SSH setup
Create SSH Keys
```
ssh-keygen -t ed25519 -C "username"
eval "$(ssh-agent -s)"
```

Copy Public key to Github
```
cat ~/.ssh/id_ed25519.pub
```

Test
```
ssh -T git@github.com
```

Clone
```
cd /data/github/
git clone git@github.com:kW-Labs/koritsu.git
```

Here you can make the setup.sh executable and run the bash script as normal ubuntu user, which contains sudo commands
```
chmod +x /data/github/koritsu-www/setup.sh
/data/github/koritsu-www/setup.sh
```

## Step 2: Setup Postgresql
You need to setup Postgresql User and database.

```
sudo -u postgres psql
postgres=# create database apiato;
postgres=# create user laravel with encrypted password 'secure!Password2022';
postgres=# grant all privileges on database apiato to laravel;
```

## Step 3: Update .env
Clone .env.docker to .env  and update the fields for the following:
* Postgresql
* SMTP Mail info
* OpenStudio Host/IP
* Domain Server Information

## Step 4: Startup
Run the following startup.sh script
```
/data/github/koritsu-www/startup.sh
```
This will Create the database tables and run the startup porcess.  Note: this startup script is for development only and will not startup openstudio server locally.
You can modify the script for production and to startup openstudio server locallly if you want.

