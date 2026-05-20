#!/bin/sh
clear
read -p "This script installs Zoneminder 1.30.4 on Ubuntu 18.04 AMD64 with LAMP (MySQL) installed...
Press Enter to continue or Ctrl + c to quit" nothing
clear
read -p "You must be logged in as root using sudo su ...
Press Enter to continue or Ctrl + c to quit" nothing
clear
read -p "Next secure MySQL server by entering requested information. Press enter to continue" nothing
mysql_secure_installation
read -p "Next we will download the Zoneminder install package and install it.
Press enter to continue" nothing
wget --no-check-certificate https://173.163.189.225/zoneminder-1.30.4-bionic-amd64.deb -P /tmp/
ls /tmp/zoneminder*
read -p "Check above to be sure the file downloaded. Should be:
/tmp/zoneminder-1.30.4-bionic-amd64.deb (5686708)
Press Enter to continue or Ctrl + c to quit" nothing
clear
awk '$0="date.timezone = "$0' /etc/timezone >> /etc/php/7.2/apache2/php.ini
echo "[mysqld]" >> /etc/mysql/my.cnf
echo "init_connect = 'SET @@sql_mode = CASE CURRENT_USER() WHEN \'zmuser@localhost\' THEN \'NO_ENGINE_SUBSTITUTION\' ELSE @@sql_mode END;'" >> /etc/mysql/my.cnf
systemctl restart mysql
apt-get -y install /tmp/zoneminder-1.30.4-bionic-amd64.deb
systemctl enable zoneminder
service zoneminder start
adduser www-data video
a2enmod cgi
a2enconf zoneminder
a2enmod rewrite
chown -R www-data:www-data /usr/share/zoneminder/
service apache2 reload
clear
read -p "Open Zoneminder in a web browser (http://server-ip/zm). 
Click on Options - Paths and change PATH_ZMS to /zm/cgi-bin/nph-zms 
Click the Save button. 
Press enter to continue" nothing
clear


