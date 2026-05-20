#!/bin/sh
clear
read -p "This script installs Apache2, Mariadb Server, PHP and Zoneminder 1.32.3 with MP4 support on Ubuntu 19.04 AMD64.
Press Enter to continue or Ctrl + c to quit" nothing
clear
read -p "You must be logged in as root using sudo su before running this script...
The script will stop and prompt for user action as required
Press Enter to continue or Ctrl + c to quit" nothing
clear
apt -y install apache2 php mariadb-server php-mysql libapache2-mod-php7.2 x264 x265 gdebi
clear
read -p "Next secure MySQL server by entering requested information. Press enter to continue" nothing
mysql_secure_installation
clear
read -p "Next we will download the libmp4v2 package and install it.
Press enter to continue" nothing
wget -O /tmp/libmp4v2-2_2.0-1_amd64.deb --no-check-certificate "https://onedrive.live.com/download?cid=DECAED2A9DCA1993&resid=DECAED2A9DCA1993%2127788&authkey=AIRJsHH6TkX22R8"
apt -y install /tmp/libmp4v2-2_2.0-1_amd64.deb
clear
read -p "Next we will download the Zoneminder (patched) package and install it.
Press enter to continue" nothing
wget -O /tmp/zoneminder_1.32.3-disco_repacked_amd64.deb --no-check-certificate "https://onedrive.live.com/download?cid=DECAED2A9DCA1993&resid=DECAED2A9DCA1993%2127790&authkey=AAa7rrbW8NadXos"
awk '$0="date.timezone = "$0' /etc/timezone >> /etc/php/7.2/apache2/php.ini
gdebi /tmp/zoneminder_1.32.3-disco_repacked_amd64.deb
systemctl enable zoneminder
service zoneminder start
adduser www-data video
a2enmod cgi
a2enconf zoneminder
a2enmod rewrite
chmod 740 /etc/zm/zm.conf
chown root:www-data /etc/zm/zm.conf
chown -R www-data:www-data /usr/share/zoneminder/
service apache2 reload
clear
read -p "Open Zoneminder in a web browser (http://server-ip/zm).
Press enter to continue" nothing
clear
