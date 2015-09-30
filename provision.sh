#!/usr/bin/env bash

# This recipe allows you to sudo command without entering your "sudo" password.
#echo "vagrant ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers
echo "vagrant ALL=(ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers

# Update Package List

apt-get update

apt-get upgrade -y

# Force Locale

echo "LC_ALL=en_US.UTF-8" >> /etc/default/locale
locale-gen en_US.UTF-8

# Install Some PPAs

apt-get install -y software-properties-common curl

apt-add-repository ppa:nginx/stable -y
apt-add-repository ppa:rwky/redis -y
apt-add-repository ppa:chris-lea/node.js -y
apt-add-repository ppa:ondrej/php5-5.6 -y
add-apt-repository -y ppa:webupd8team/java
add-apt-repository -y ppa:webupd7team/java

wget -O - http://packages.elasticsearch.org/GPG-KEY-elasticsearch | sudo apt-key add -
echo 'deb http://packages.elasticsearch.org/elasticsearch/1.4/debian stable main' | sudo tee /etc/apt/sources.list.d/elasticsearch.list

wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main" >> /etc/apt/sources.list.d/postgresql.list'

curl -s https://packagecloud.io/gpg.key | sudo apt-key add -
echo "deb http://packages.blackfire.io/debian any main" | sudo tee /etc/apt/sources.list.d/blackfire.list

# Update Package Lists

apt-get update

# Install Some Basic Packages

apt-get install -y build-essential dos2unix gcc git libmcrypt4 libpcre3-dev \
make python2.7-dev python-pip re2c supervisor unattended-upgrades whois
sudo update-rc.d supervisor defaults

# Set My Timezone

ln -sf /usr/share/zoneinfo/Europe/Podgorica /etc/localtime

install_keypar(){
# create key-pair for bitbucket
ssh-keygen -f /home/vagrant/.ssh/id_rsa.bitbucket
chown vagrant:vagrant /home/vagrant/.ssh/id_rsa.bitbucket
chown vagrant:vagrant /home/vagrant/.ssh/id_rsa.bitbucket.pub
# chmod 600 /home/vagrant/.ssh/id_bitbucket
# chmod 600 /home/vagrant/.ssh/id_bitbucket.pub
cat << __EOT__ >> /home/vagrant/.ssh/config
Host bitbucket.org 
  IdentityFile /home/vagrant/.ssh/id_rsa.bitbucket
__EOT__
chown vagrant:vagrant /home/vagrant/.ssh/config
echo "Provjeri: ssh -T git@bitbucket.org"  
}

# echo "================================================="
# echo "Instaliraj SSH key? [y / n]"
# echo "================================================="
# read instalar
# if [ $instalar == 'y' ]; then
#   install_keypar
# fi


# Install PHP Stuffs

apt-get install -y --force-yes php5-cli php5-dev php-pear php5-mysqlnd php5-pgsql php5-sqlite php5-apcu php5-json php5-curl php5-gd php5-gmp php5-imap php5-mcrypt php5-xdebug php5-memcached

# Make MCrypt Available

ln -s /etc/php5/conf.d/mcrypt.ini /etc/php5/mods-available
sudo php5enmod mcrypt

# Install Mailparse PECL Extension

sudo pecl install mailparse
echo "extension=mailparse.so" > /etc/php5/mods-available/mailparse.ini
ln -s /etc/php5/mods-available/mailparse.ini /etc/php5/cli/conf.d/20-mailparse.ini

# Install Composer

curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

# Add Composer Global Bin To Path

printf "\nPATH=\"/home/vagrant/.composer/vendor/bin:\$PATH\"\n" | tee -a /home/vagrant/.profile

# Install Laravel Envoy

sudo su vagrant <<'EOF'
/usr/local/bin/composer global require "laravel/envoy=~1.0"
EOF

# Set Some PHP CLI Settings

sudo sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php5/cli/php.ini
sudo sed -i "s/display_errors = .*/display_errors = On/" /etc/php5/cli/php.ini
sudo sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php5/cli/php.ini
sudo sed -i "s/;date.timezone.*/date.timezone = UTC/" /etc/php5/cli/php.ini

# Install Nginx & PHP-FPM

apt-get install -y --force-yes nginx php5-fpm

rm /etc/nginx/sites-enabled/default
rm /etc/nginx/sites-available/default
NGINX_CONFIG="/etc/nginx/sites-available/default"
 
cat <<EOF > $NGINX_CONFIG
server {
    listen 80;
    server_name dms.local;
    root /home/vagrant/default/public;

    index index.html index.htm index.php;
    charset utf-8;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    access_log off;
    error_log  /var/log/nginx/dms.app-error.log error;

    error_page 404 /index.php;

    sendfile off;

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/var/run/php5-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF
ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default
service nginx restart
sudo update-rc.d nginx defaults
# Add The HHVM Key & Repository

# wget -O - http://dl.hhvm.com/conf/hhvm.gpg.key | apt-key add -
# echo deb http://dl.hhvm.com/ubuntu utopic main | tee /etc/apt/sources.list.d/hhvm.list
# apt-get update
# apt-get install -y hhvm

# # Configure HHVM To Run As Homestead

# service hhvm stop
# sed -i 's/#RUN_AS_USER="www-data"/RUN_AS_USER="vagrant"/' /etc/default/hhvm
# service hhvm start

# Start HHVM On System Start

# update-rc.d hhvm defaults

# Setup Some PHP-FPM Options

ln -s /etc/php5/mods-available/mailparse.ini /etc/php5/fpm/conf.d/20-mailparse.ini

sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php5/fpm/php.ini
sed -i "s/display_errors = .*/display_errors = On/" /etc/php5/fpm/php.ini
sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php5/fpm/php.ini
sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php5/fpm/php.ini
sed -i "s/upload_max_filesize = .*/upload_max_filesize = 100M/" /etc/php5/fpm/php.ini
sed -i "s/;date.timezone.*/date.timezone = UTC/" /etc/php5/fpm/php.ini

# echo "xdebug.remote_enable = 1" >> /etc/php5/fpm/conf.d/20-xdebug.ini
# echo "xdebug.remote_connect_back = 1" >> /etc/php5/fpm/conf.d/20-xdebug.ini
# echo "xdebug.remote_port = 9000" >> /etc/php5/fpm/conf.d/20-xdebug.ini
# echo "xdebug.max_nesting_level = 250" >> /etc/php5/fpm/conf.d/20-xdebug.ini

# Copy fastcgi_params to Nginx because they broke it on the PPA

cat > /etc/nginx/fastcgi_params << EOF
fastcgi_param	QUERY_STRING		\$query_string;
fastcgi_param	REQUEST_METHOD		\$request_method;
fastcgi_param	CONTENT_TYPE		\$content_type;
fastcgi_param	CONTENT_LENGTH		\$content_length;
fastcgi_param	SCRIPT_FILENAME		\$request_filename;
fastcgi_param	SCRIPT_NAME		\$fastcgi_script_name;
fastcgi_param	REQUEST_URI		\$request_uri;
fastcgi_param	DOCUMENT_URI		\$document_uri;
fastcgi_param	DOCUMENT_ROOT		\$document_root;
fastcgi_param	SERVER_PROTOCOL		\$server_protocol;
fastcgi_param	GATEWAY_INTERFACE	CGI/1.1;
fastcgi_param	SERVER_SOFTWARE		nginx/\$nginx_version;
fastcgi_param	REMOTE_ADDR		\$remote_addr;
fastcgi_param	REMOTE_PORT		\$remote_port;
fastcgi_param	SERVER_ADDR		\$server_addr;
fastcgi_param	SERVER_PORT		\$server_port;
fastcgi_param	SERVER_NAME		\$server_name;
fastcgi_param	HTTPS			\$https if_not_empty;
fastcgi_param	REDIRECT_STATUS		200;
EOF

# Set The Nginx & PHP-FPM User

sed -i "s/user www-data;/user vagrant;/" /etc/nginx/nginx.conf
sed -i "s/# server_names_hash_bucket_size.*/server_names_hash_bucket_size 64;/" /etc/nginx/nginx.conf

sed -i "s/user = www-data/user = vagrant/" /etc/php5/fpm/pool.d/www.conf
sed -i "s/group = www-data/group = vagrant/" /etc/php5/fpm/pool.d/www.conf

sed -i "s/listen\.owner.*/listen.owner = vagrant/" /etc/php5/fpm/pool.d/www.conf
sed -i "s/listen\.group.*/listen.group = vagrant/" /etc/php5/fpm/pool.d/www.conf
sed -i "s/;listen\.mode.*/listen.mode = 0666/" /etc/php5/fpm/pool.d/www.conf

service nginx restart
service php5-fpm restart

# Add Vagrant User To WWW-Data

usermod -a -G www-data vagrant
id vagrant
groups vagrant

# Install Node

# apt-get install -y nodejs
# /usr/bin/npm install -g grunt-cli
# /usr/bin/npm install -g gulp
# /usr/bin/npm install -g bower

# Install SQLite

apt-get install -y sqlite3 libsqlite3-dev

# Install MySQL

debconf-set-selections <<< "mysql-server mysql-server/root_password password secret"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password secret"
apt-get install -y mysql-server-5.6

# Configure MySQL Remote Access

sed -i '/^bind-address/s/bind-address.*=.*/bind-address = 0.0.0.0/' /etc/mysql/my.cnf
mysql --user="root" --password="secret" -e "GRANT ALL ON *.* TO root@'0.0.0.0' IDENTIFIED BY 'secret' WITH GRANT OPTION;"
service mysql restart

mysql --user="root" --password="secret" -e "CREATE USER 'homestead'@'0.0.0.0' IDENTIFIED BY 'secret';"
mysql --user="root" --password="secret" -e "GRANT ALL ON *.* TO 'homestead'@'0.0.0.0' IDENTIFIED BY 'secret' WITH GRANT OPTION;"
mysql --user="root" --password="secret" -e "GRANT ALL ON *.* TO 'homestead'@'%' IDENTIFIED BY 'secret' WITH GRANT OPTION;"
mysql --user="root" --password="secret" -e "FLUSH PRIVILEGES;"
mysql --user="root" --password="secret" -e "CREATE DATABASE homestead;"
service mysql restart
sudo update-rc.d mysql defaults

# Add Timezone Support To MySQL

mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql --user=root --password=secret mysql

# Install Postgres

# apt-get install -y postgresql-9.4 postgresql-contrib-9.4

# Configure Postgres Remote Access

# sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" /etc/postgresql/9.4/main/postgresql.conf
# echo "host    all             all             10.0.2.2/32               md5" | tee -a /etc/postgresql/9.4/main/pg_hba.conf
# sudo -u postgres psql -c "CREATE ROLE homestead LOGIN UNENCRYPTED PASSWORD 'secret' SUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION;"
# sudo -u postgres /usr/bin/createdb --echo --owner=homestead homestead
# service postgresql restart

# Install Blackfire

# apt-get install -y blackfire-agent blackfire-php

# Install A Few Other Things

apt-get install -y redis-server memcached beanstalkd

# Configure Beanstalkd

sudo sed -i "s/#START=yes/START=yes/" /etc/default/beanstalkd
#sudo /etc/init.d/beanstalkd start
sudo service beanstalkd start
sudo update-rc.d beanstalkd defaults


# Enable Swap Memory

# /bin/dd if=/dev/zero of=/var/swap.1 bs=1M count=1024
# /sbin/mkswap /var/swap.1
# /sbin/swapon /var/swap.1

if [ -f /swapfile ]; then
	echo "Swap file already exists."
else
	sudo fallocate -l 1G /swapfile
  sudo chmod 600 /swapfile
  sudo mkswap /swapfile
  sudo swapon /swapfile
  echo "/swapfile   none    swap    sw    0   0" >> /etc/fstab
  echo "vm.swappiness=30" >> /etc/sysctl.conf
  echo "vm.vfs_cache_pressure=50" >> /etc/sysctl.conf
  echo "Swap created and added to /etc/fstab for boot up."
fi



# Minimize The Disk Image
# echo "Minimizing disk image..."
# dd if=/dev/zero of=/EMPTY bs=1M
# rm -f /EMPTY
# sync

# install java
#sudo apt-get install openjdk-7-jre-headless -y
#sudo apt-get -y install oracle-java8-installer
install_java(){
sudo apt-get -y install oracle-java8-installer 
}
echo "Instaliraj javu 8. [y / n]"
echo "================================================="
read instalar
if [ $instalar == 'y' ]; then
  install_java
fi

install_elasticsearch(){
# install elasticsearch
# wget https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.1.1.deb
# sudo dpkg -i elasticsearch-1.1.1.deb
sudo apt-get -y install elasticsearch=1.4.4
sudo service elasticsearch start
sudo update-rc.d elasticsearch defaults 95 10

# Elastic search memory
# /etc/security/limits.conf
echo "elasticsearch - nofile 65535" | sudo tee -a /etc/security/limits.conf
echo "elasticsearch - memlock unlimited" | sudo tee -a /etc/security/limits.conf
# /etc/default/elasticsearch:

# ES_HEAP_SIZE=1024m
# MAX_OPEN_FILES=65535
# MAX_LOCKED_MEMORY=unlimited

# /etc/elasticsearch/elasticsearch.yml:
# bootstrap.mlockall: true
 
# install head
sudo /usr/share/elasticsearch/bin/plugin -install mobz/elasticsearch-head
# http://localhost:9200/_plugin/head/
}
echo "Instaliraj elasticsearch 1.4.4? [y / n]"
echo "================================================="
read instalar
if [ $instalar == 'y' ]; then
  install_elasticsearch
fi

install_unoconv(){
  ### install unoconv
sudo apt-get install unoconv
}

echo "Instaliraj unoconv? [y / n]"
echo "================================================="
read instalar
if [ $instalar == 'y' ]; then
  install_unoconv
fi

install_wkhtmltopdf(){
### install wkhtmltopdf
sudo apt-get install openssl build-essential xorg libssl-dev libxrender-dev
sudo apt-get install wkhtmltopdf
}

echo "Instaliraj wkhtmltopdf? [y / n]"
echo "================================================="
read instalar
if [ $instalar == 'y' ]; then
  install_wkhtmltopdf
fi

install_ocr(){
## Instalacija zavisnosti
sudo apt-get install poppler-utils
sudo apt-get install imagemagick
sudo apt-get install libjpeg-dev libpng-dev libtiff4-dev
## Leptonica
cd /tmp
wget http://leptonica.googlecode.com/files/leptonica-1.69.tar.bz2
tar xvf leptonica-1.69.tar.bz2
cd leptonica-1.69
./configure
make
sudo make install
sudo ldconfig
cd /tmp
# Install Tesseract
wget https://tesseract-ocr.googlecode.com/files/tesseract-ocr-3.02.02.tar.gz
tar zxvf tesseract-ocr-3.02.02.tar.gz
cd tesseract-ocr
./autogen.sh
./configure
make
sudo make install
sudo ldconfig
cd /tmp

# Preuzmi language fajlove
# wget https://tesseract-ocr.googlecode.com/files/tesseract-ocr-3.02.eng.tar.gz
wget https://tesseract-ocr.googlecode.com/files/tesseract-ocr-3.02.srp.tar.gz
#tar zxvf tesseract-ocr-3.02.eng.tar.gz
tar zxvf tesseract-ocr-3.02.srp.tar.gz
sudo cp tesseract-ocr/tessdata/srp.traineddata  tessdata/srp.traineddata
sudo cp tesseract-ocr/tessdata/srp.traineddata  tessdata/eng.traineddata

}

echo "Instaliraj ocr from source? [y / n]"
echo "================================================="
read instalar
if [ $instalar == 'y' ]; then
  install_ocr
fi

install_ocr_package(){
sudo apt-get install tesseract-ocr
sudo apt-get install tesseract-ocr-eng
sudo apt-get install tesseract-ocr-srp
sudo apt-get install ghostscript
}

echo "Instaliraj ocr from package? [y / n]"
echo "================================================="
read instalar
if [ $instalar == 'y' ]; then
  install_ocr_package
fi

install_repo() {
mkdir ~/default
chown vagrant:vagrant ~/default
cd ~ && git clone --mirror git@bitbucket.org:ognjenm/dms.git
chown -R vagrant:vagrant dms.git
cd ~/dms.git
GIT_WORK_TREE=/home/vagrant/default git checkout -f master
cd ~/default
composer install
mkdir repository
cd repository
mkdir dokumenta predmeti public projects tasks preview users logos
cd ..
chmod -Rf 777 repository/
php artisan migrate
php artisan db:seed

echo "Ne zaboravi da odradis http://localhost/rebuildMapping"
}
echo "kopiraj sadrzaj fajla /home/vagrant/.ssh/id_rsa.bitbucket.pub"
cat /home/vagrant/.ssh/id_rsa.bitbucket.pub
echo "kada je gotovo unesi y. [y / n]"
echo "================================================="
read instalar
if [ $instalar == 'y' ]; then
  install_repo
fi

install_tika_service() {
tika_url="http://central.maven.org/maven2/org/apache/tika/tika-server/1.5/tika-server-1.5.jar"
tika_sh_url="https://raw.githubusercontent.com/galkan/depdep/master/script/tika.sh"
tika_dir="/opt/tika"
tika_sh="tika"
etc_dir="/etc/init.d"

current_dir="`pwd`"

for dir in $tika_dir $etc_dir
do
  if [ ! -d "$dir" ]
  then
          sudo mkdir $dir
  fi
done


cd $tika_dir
sudo rm -f tika*
sudo wget $tika_url
if [ ! $? -eq 0 ]
then
  echo "Cannot download Apache Tika ($tika_url). Please try again later ..."
  exit 1  
fi
sudo wget $tika_sh_url -O tika
if [ ! $? -eq 0 ]
then
  echo "Cannot download Apache start/stop script ($tika_sh_url). Please try again later ..."
  exit 1  
fi
cd $current_dir
# sudo cp $tika_sh $etc_dir
sudo cp /opt/tika/tika /etc/init.d

for file in "$etc_dir/$tika_sh" 
do
  sudo chown root:root $file
  sudo chmod 755 $file
  sudo service tika start
  sudo update-rc.d tika defaults
done
clear
echo "Tika servis instaliran"
}

echo "Instaliraj Tika servis? [y / n]"
echo "================================================="
read instalar
if [ $instalar == 'y' ]; then
  install_tika_service
fi
