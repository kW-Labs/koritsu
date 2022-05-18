### This is a refactor of Koritsu to use OpenStudio-analysis and OpenStudio-server

See: https://github.com/DavidGoldwasser/osw2osa

- install bundle using `gem install bundle`
- Run `bundle install` from top level of repository

---
# Getting OpenStudio Working in Ubuntu 

## Install Ruby 2.7.2
First we need to install the version of Ruby that will will work with OpenStudio, which is 2.7.2
```
sudo apt install -y build-essential libssl-dev libreadline-dev zlib1g-dev

wget -q https://github.com/rbenv/rbenv-installer/raw/master/bin/rbenv-installer -O- | bash

echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc

echo 'if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi' >> ~/.bashrc

source ~/.bashrc

rbenv install 2.7.2

rbenv global 2.7.2
```

## Install OpenStudio Ubuntu package
(if on Ubuntu 18.04)

```
wget https://github.com/NREL/OpenStudio/releases/download/v3.3.0/OpenStudio-3.3.0+ad235ff36e-Ubuntu-18.04.deb

sudo dpkg -i OpenStudio-3.3.0+ad235ff36e-Ubuntu-18.04.deb
```

## Connect OpenStudio to system ruby
```
cd ~/.rbenv/versions/2.7.2/lib/ruby/site_ruby

echo "require '/usr/local/openstudio-3.3.0/Ruby/openstudio.rb'" > openstudio.rb
```


## Install Gems
```
gem install bundler
bundle install
```
## Add OpenStudio to .profile (note: only need to set RUBYLIB if using Ruby packaged with OpenStudio)
```
vi .profile

# set RUBYLIB path
export RUBYLIB=/usr/local/openstudio-3.1.0/Ruby
```


## Connect OpenStudio to local Ruby (if using system Ruby)
```
cd ~/.rbenv/versions/2.5.5/lib/ruby/site_ruby/

echo "require '/usr/local/openstudio-3.1.0/Ruby/openstudio.rb'" > openstudio.rb
```

## Update profile (don't need to do this if using system Ruby)
```
export GEM_PATH=/home/ubuntu/.rbenv/versions/2.7.2/lib/ruby/gems/2.7.0/gems
```

## Install Gems
This gem might hang at the documenation stage, so press `Ctrl+C` to cancel and try running the command again
```
gem install openstudio-standards --verbose
```

## Testing OpenStudio 
Log out and back in to test the following and to get the profile back
```
irb
require 'openstudio'
```

## Now you can install the github repo and test

---

# OpenStudio-server local setup for testing

## Installing the server
Download latest release and extract
```
# doing this on the desktop
cd ~/Desktop
# download server
wget https://github.com/NREL/OpenStudio-server/archive/refs/tags/v3.3.0.tar.gz
# extract
tar -xf v3.3.0.tar.gz
```
Create server directory and subdirectories
```
mkdir -p OS-server/logs OS-server/data/db
```

## Using the Server
First time startup
```
cd OpenStudio-server-3.3.0

# you might need to first install some dependencies
# e.g. mongodb, see: https://docs.mongodb.com/manual/tutorial/install-mongodb-on-ubuntu/
# also whatever these are:
sudo apt-get install libxslt-dev libxml2-dev
# now install gems (this will take a little while)
bin/openstudio_meta install_gems
# start local server
bin/openstudio_meta start_local ~/Desktop/OS-server
```

## Stopping local server
```
cd OpenStudio-server-3.3.0

bin/openstudio_meta stop_local ~/OS-server
```

Additional notes:
- when stopping local server, mongodb process remains open, and 'local_configuration.json' file are deleted.
    - Try: copying local_configuration before shutdown OR commenting out line that deletes it from openstudio_meta
    - Try: stopping mongodb by running this from terminal:
    `mongod --dbpath ~/Dektop/OS-server/data/db --shutdown`
    
