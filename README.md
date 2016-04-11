# WordPressDeployer
Deploys multiple wordpress instances and configures MySQL and Apache services automatically.
This script is intended for test environments but can be used for production if one so wishes.  The WP_PORT variable should be modified if you wish to use a different starting point.  The default starting port is 8080 and each site will be assigned the next available port.

#### Pre-requisites
LAMP stack and Bash.  This was developed and tested on Ubuntu Server 14.04.4 LTS.

#### newWPSite.sh
Creates WordPress sites.  User must be in the sudoers group to execute this script.

Usage: ./newWPSite.sh <site1> [site2] [site3] ...

#### deleteWPSite.sh
An extra utility that helps reverse the effects of newWPSite.sh.  User must be in the sudoers group to execute this script.

Usage: ./deleteWPSite.sh  <site1> [site2] [site3] ...
