#!/bin/bash

# If no site names have been supplied exit the script
if [[ $# < 1 ]]; then
	echo "Usage: $0 <site1> [site2] [site3] [...]";
	exit;
fi

# Check if the user is root.  If not elevate privs
if [ $(id -u) != "0" ]; then
	sudo "$0" "$@"
	exit $?
fi

printf "=================================\n";
printf "#                               #\n";
printf "#      WordPress Deployer v1    #\n";
printf "#                               #\n";
printf "=================================\n\n";

# Download the latest version of WordPress if it doesn't exist on the system already
if [[ ! -d ./wordpress/ ]]; then
	wget http://wordpress.org/latest.tar.gz
	printf "Unpacking...\n\n";
	tar xzvf latest.tar.gz > /dev/null;
	rm -rf latest.tar.gz

	# Make a copy of the sample WP configuration
        cp ./wordpress/wp-config-sample.php ./wordpress/wp-config.php;
fi

# Check if php5-gd is installed on the server
if [[ -z $(dpkg -l | grep php5-gd) ]]; then
	printf "\n[!] Installing php5-gd\n";
	printf "======================\n\n";
	echo -n "Continue...";
	read;
	apt-get install php5-gd;
	echo "\n\n";
fi

# Get the MySQL user
echo -n "MySQL username [root]: ";
read DB_USER;
if [[ -z $DB_USER ]]; then
	DB_USER="root";
fi

# Get the MySQL password
echo -n "MySQL password: ";
read -s DB_PASS;
printf "\n\n";

# Starting port for each new server
WP_PORT=8080;

# Status text
SITE_INFO="";

# Iterate over the site names and create databases for them as well
# as setup directories for them
while [[ $# > 0 ]]; do
	clear;
	printf "\n=========================================\n";
	printf "  Creating database: $1                    \n";
	printf "=========================================\n\n";
	mysql -u root -p$DB_PASS -e "CREATE DATABASE $1";

	# Get user account and password for this database
	printf "\n[!] Database Account\n";
	printf "====================\n\n";
	echo -n "User: ";
	read WP_DB_USER;
	mysql -u root -p$DB_PASS -e "CREATE USER $WP_DB_USER@localhost";

	# Set a password for this user
	echo -n "Password: ";
	read -s WP_DB_PASS;
	mysql -u root -p$DB_PASS -e "GRANT ALL PRIVILEGES ON $1.* TO $WP_DB_USER@localhost IDENTIFIED BY '$WP_DB_PASS'";

	# Create a directory for this site
	mkdir /var/www/$1;

	# Copy the WP files to the site directory
	printf "\n\n[!] Copying files\n";
	rsync -aP ./wordpress/ /var/www/$1 2>&1 > /dev/null;
	printf "[!] Finished copying files\n\n";

	# Change ownership of the directory
	printf "\n[!] Changing ownership of site\n";
	printf "==============================\n\n";
	chown www-data:www-data * -R
	echo -n "Linux account to manage site: ";
	read ACC_NAME;
	usermod -a -G www-data $ACC_NAME;

	# Modify the wp-config.php file to include the database username and password
	printf "\n[!] Adding database information to wp-config.php\n";
	printf "================================================\n\n";
	sed -i "/define('DB_NAME',/c\define('DB_NAME','$1');" /var/www/$1/wp-config.php;
	sed -i "/define('DB_USER',/c\define('DB_USER','$WP_DB_USER');" /var/www/$1/wp-config.php;
	sed -i "/define('DB_PASSWORD',/c\define('DB_PASSWORD','$WP_DB_PASS');" /var/www/$1/wp-config.php;

	# Create a new virtual host file for the site
	printf "\n[!] Creating Virtual Host Configuration File\n";
	printf "============================================\n\n";

	# Find a port that is not currently being used
	FREE_PORT=false;
	while [[ $FREE_PORT == false ]]; do
		if [[ -n $(netstat -na | grep $WP_PORT) ]]; then
			WP_PORT=$((WP_PORT+1));
		else
			FREE_PORT=true;
		fi
	done

	read -r -d '' VHOST_CFG << EOCFG
Listen $WP_PORT
<VirtualHost *:$WP_PORT>
	ServerAdmin	webmaster@localhost
	ServerName	$1
	ServerAlias	www.$1.com
	DocumentRoot	/var/www/$1
	<Directory />
		Options FollowSymLinks
		AllowOverride None
	</Directory>
	<Directory /var/www/$1>
		Options Indexes FollowSymLinks MultiViews
		AllowOverride All
		Order allow,deny
		allow from all
	</Directory>
</VirtualHost>
EOCFG

	echo "$VHOST_CFG" >> /etc/apache2/sites-available/$1.conf;
	a2ensite $1.conf;

	# Update Site Info
	SITE_INFO="$SITE_INFO\n $1 Listening on $WP_PORT";

	WP_PORT=$((WP_PORT+1));

shift;
done

# Flush MySQL privs
printf "\n[!] Flushing MySQL Privs\n";
printf "========================\n\n";
mysql -u root -p$DB_PASS -e "FLUSH PRIVILEGES";

# Restart Apache Service
printf "\n[!] Restarting Apache\n";
printf "=====================\n\n";
service apache2 restart;

clear;
printf "\n\nResults:\n";
printf "===============================================================\n\n";
printf "$SITE_INFO";
printf "\n\n";
