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

# Get the MySQL user
echo -n "MySQL username [root]: ";
read DB_USER;
if [[ -z $DB_USER ]]; then
	DB_USER="root";
fi

# Get the MySQL password
echo -n "MySQL password: ";
read -s DB_PASS;
echo "";

# Iterate over the site names and create databases for them as well
# as setup directories for them
while [[ $# > 0 ]]; do
	mysql -u root -p$DB_PASS -e "DROP DATABASE $1";

	# Get user account and password for this database
	echo "Database Account";
	echo "================";
	echo -n "User: ";
	read WP_DB_USER;
	mysql -u root -p$DB_PASS -e "DROP USER $WP_DB_USER@localhost";

	rm -rf /var/www/$1;
	rm -rf /etc/apache2/sites-available/$1.conf;
	rm -rf /etc/apache2/sites-enabled/$1.conf;

shift;
done

# Flush MySQL privs
mysql -u root -p$DB_PASS -e "FLUSH PRIVILEGES";

service apache2 restart
