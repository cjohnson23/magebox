#!/bin/bash

VAGRANT_CORE_FOLDER=$(cat '/.puphpet-stuff/vagrant-core-folder.txt')

if [[ -f '/.puphpet-stuff/ran-magebox' ]]; then
    exit 0
fi

cat "${VAGRANT_CORE_FOLDER}/shell/ascii-art/magebox.txt"

echo "Running MageBox specific tasks"
chmod 777 /tmp/pear/temp/
pear channel-discover pear.symfony-project.com
pear channel-discover components.ez.no
pear install pear.symfony-project.com/YAML-1.0.2
pear install symfony/YAML

DAY=$(date +"%d")-1
#NOW=$(date +"%Y%m%d")
NOW="20150528"
GZFILE="liveoutt_sample_$NOW.sql.gz"
FILE="liveoutt_sample_$NOW.sql"
MTAF="magebox.liveoutthere.com"
HOSTNAME="magebox.liveoutthere.com"
MAGERUN=".n98-magerun.yaml"
DBHOST="localhost"
DBUSER="liveoutt_11"
RDBUSER="root"
PASSWORD="password"
DBNAME="liveoutt_development"
dbpass="mypassword" && export dbpass
HR="------------------------------------------------------"
export DEBIAN_FRONTEND=noninteractive
echo percona-server-server-5.5 percona-server-server/root_password password $PASSWORD | debconf-set-selections
echo percona-server-server-5.5 percona-server-server/root_password_again password $PASSWORD | debconf-set-selections

echo "$HR"
echo "Adding Selenium Server..."
curl -L -s -o /usr/local/bin/selenium-server-standalone-2.45.0.jar http://selenium-release.storage.googleapis.com/2.45/selenium-server-standalone-2.45.0.jar
chmod +x /usr/local/bin/selenium-server-standalone-2.45.0.jar

echo "$HR"
echo "Getting Sample Data..."
curl -L -s -o $GZFILE https://s3.amazonaws.com/lot-db-backups/sample/$GZFILE
gzip -d $FILE
chown vagrant $FILE
chgrp vagrant $FILE

echo "$HR"
echo "Getting Magerun..."
curl -L -s -o /usr/local/bin/n98-magerun.phar http://files.magerun.net/n98-magerun-latest.phar
chmod +x /usr/local/bin/n98-magerun.phar
echo 'suhosin.executor.include.whitelist="phar"' | sudo tee -a /etc/php5/fpm/php.ini
cp /vagrant/liveoutthere/$MAGERUN /home/vagrant/$MAGERUN
chown vagrant $MAGERUN
chgrp vagrant $MAGERUN

echo "$HR"
echo "Getting Phpunit..."
curl -L -s -o /usr/local/bin/phpunit.phar https://phar.phpunit.de/phpunit.phar
chmod +x /usr/local/bin/phpunit.phar

echo "$HR"
echo "Creating Code Repositories..."
cp /vagrant/liveoutthere/config ~/.ssh/config
mkdir -p /vagrant/mtaf
cd /vagrant/mtaf
echo "Getting mtaf code..."
git clone https://github.com/magento/taf.git .
chown -R vagrant /vagrant/mtaf
chgrp -R vagrant /vagrant/mtaf
mkdir -p /var/www/html
cd /var/www/html
rm index.html
echo "Getting liveoutthere.com code..."
git clone git@liveoutthere.git.beanstalkapp.com:/liveoutthere/live-out-there.git .


echo "$HR"
echo "Getting Percona & configuring..."

apt-key adv --keyserver keys.gnupg.net --recv-keys 1C4CBDCDCD2EFD2A

echo "#percona repositories" | sudo tee -a /etc/apt/sources.list
echo "deb http://repo.percona.com/apt wheezy main" | sudo tee -a /etc/apt/sources.list
echo "deb-src http://repo.percona.com/apt wheezy main" | sudo tee -a /etc/apt/sources.list
apt-get update
apt-get -y install percona-server-server-5.5 percona-server-client-5.5



echo "creating database user for liveoutthere.com"
mysql -u $RDBUSER -p$PASSWORD -e "CREATE USER '$DBUSER'@'%' IDENTIFIED BY '$PASSWORD';"
mysql -u $RDBUSER -p$PASSWORD -e "CREATE USER '$DBUSER'@'localhost' IDENTIFIED BY '$PASSWORD';"
mysql -u $RDBUSER -p$PASSWORD -e "CREATE USER '$DBUSER'@'127.0.0.1' IDENTIFIED BY '$PASSWORD';"
mysql -u $RDBUSER -p$PASSWORD -e "CREATE DATABASE $DBNAME;"
mysql -u $RDBUSER -p$PASSWORD -e "GRANT ALL PRIVILEGES ON *.* TO '$DBUSER'@'%';"
mysql -u $RDBUSER -p$PASSWORD -e "GRANT ALL PRIVILEGES ON *.* TO '$DBUSER'@'localhost';"
mysql -u $RDBUSER -p$PASSWORD -e "GRANT ALL PRIVILEGES ON *.* TO '$DBUSER'@'127.0.0.1';"
mysql -u $RDBUSER -p$PASSWORD -e "FLUSH PRIVILEGES;"

echo "importing database"
mysql -u $RDBUSER -p$PASSWORD $DBNAME < /home/vagrant/$FILE
#mysql -u $RDBUSER -p$PASSWORD $DBNAME < /vagrant/liveoutt_development.sql

echo "updating database for magebox hostname"

mysql -h $DBHOST -u $DBUSER -p$PASSWORD $DBNAME -e "UPDATE $DBNAME.core_config_data SET value = '$HOSTNAME/' WHERE config_id IN (662,1417,1418);"
mysql -h $DBHOST -u $DBUSER -p$PASSWORD $DBNAME -e "UPDATE $DBNAME.core_config_data SET value = '$HOSTNAME/skin/' WHERE config_id IN (663,667);"
mysql -h $DBHOST -u $DBUSER -p$PASSWORD $DBNAME -e "UPDATE $DBNAME.core_config_data SET value = '$HOSTNAME/media/' WHERE config_id IN (664,668);"
mysql -h $DBHOST -u $DBUSER -p$PASSWORD $DBNAME -e "UPDATE $DBNAME.core_config_data SET value = '$HOSTNAME/js/' WHERE config_id IN (665,669);"
mysql -h $DBHOST -u $DBUSER -p$PASSWORD $DBNAME -e "UPDATE $DBNAME.core_config_data SET value='' WHERE config_id in (681,2038,2034);"
mysql -h $DBHOST -u $DBUSER -p$PASSWORD $DBNAME -e "UPDATE $DBNAME.core_config_data SET value = '0' WHERE config_id IN (885,1580);"
mysql -h $DBHOST -u $DBUSER -p$PASSWORD $DBNAME -e "UPDATE $DBNAME.core_config_data SET value = '1' WHERE config_id IN (402,1249);"
mysql -h $DBHOST -u $DBUSER -p$PASSWORD $DBNAME -e "UPDATE $DBNAME.core_config_data SET value = '6BCyos4CJkH1A+C1mXj1Y5SsPmuhJo0iSuFIs2/KU6Y=' WHERE config_id IN (1246);"
mysql -h $DBHOST -u $DBUSER -p$PASSWORD $DBNAME -e "UPDATE $DBNAME.core_config_data SET value = 'AqdjtPDfRGQoRCtXr9Eo0A==' WHERE config_id IN (1247);"
mysql -h $DBHOST -u $DBUSER -p$PASSWORD $DBNAME -e "UPDATE $DBNAME.core_config_data SET value = 'EcXrM7mTow0veRCByN3Q8oJHZEn8ypWppzfofenIEXkoChh14AZDX1VeVp0otU0NfdEWT3G3S0w=' WHERE config_id IN (1248);"
mysql -h $DBHOST -u $DBUSER -p$PASSWORD $DBNAME -e "UPDATE $DBNAME.core_config_data SET value = 'development' WHERE config_id IN (1867);"
mysql -h $DBHOST -u $DBUSER -p$PASSWORD $DBNAME -e "UPDATE $DBNAME.core_config_data SET value = 'riH+FAva3ITgouhNEI6YBO1lf660oGdt' WHERE config_id IN (1869);"
mysql -h $DBHOST -u $DBUSER -p$PASSWORD $DBNAME -e "UPDATE $DBNAME.core_config_data SET value = 'o8dzs97RbiQsH/srTcUha82rhPBIEy0c' WHERE config_id IN (1870);"
mysql -h $DBHOST -u $DBUSER -p$PASSWORD $DBNAME -e "UPDATE $DBNAME.core_config_data SET value = 'disabled' WHERE config_id IN (1937);DELETE FROM core_config_data WHERE config_id IN (1368,1860,1861,538,1088,1609);"
mysql -h $DBHOST -u $DBUSER -p$PASSWORD $DBNAME -e "UPDATE $DBNAME.core_config_data SET value = 'devel-liveoutthere' where path = 'payment/optimal_profiles/profile_key';"
mysql -h $DBHOST -u $DBUSER -p$PASSWORD $DBNAME -e "UPDATE $DBNAME.core_config_data SET value = '' WHERE config_id IN (694);"
mysql -h $DBHOST -u $DBUSER -p$PASSWORD $DBNAME -e "UPDATE $DBNAME.core_config_data SET value = 'disabled' WHERE config_id IN (1959);"

service mysql stop
rm /etc/mysql/my.cnf
cp /vagrant/liveoutthere/my.cnf /etc/mysql/my.cnf
service mysql start

echo "$HR"
echo "Configuring Magento for first run..."
cp /vagrant/liveoutthere/local.xml /var/www/html/app/etc/local.xml

echo "$HR"
echo "Configuring Nginx"
cp /vagrant/liveoutthere/$HOSTNAME /etc/nginx/sites-available/$HOSTNAME
cd /etc/nginx/sites-enabled/
rm *
ln -s /etc/nginx/sites-available/$HOSTNAME /etc/nginx/sites-enabled/$HOSTNAME
service nginx stop
service nginx start
echo "$HR"
echo "Magebox for liveoutthere.com configuration is now complete."
echo "Running Composer Update and Gulp requirements shouldn't be done by Root. You'll have to do that yourself."

npm install gulp
npm install gulp-autoprefixer
npm install gulp-concat
npm install gulp-group-css-media-queries
npm install gulp-csso
npm install gulp-sass
npm install gulp-uglify


touch '/.puphpet-stuff/ran-magebox'