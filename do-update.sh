#!/bin/bash
#
# Name:    do-update
# Version: 1.5 (2017-11-01)
# URL:     https://www.joepitt.co.uk/Project/do-update/
#
# This work is licensed under the Creative Commons
# Attribution-NonCommercial-ShareAlike 4.0 International License. To view a
# copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.

# Check running as root
if [ "$(id -u)" != "0" ]; then
	if hash sudo 2>/dev/null; then
		# Self-Elevate to root
		sudo $0
		exit $?
	else
		echo "do-update must be run as root, however, sudo is not installed so I cannot self elevate."
		exit 1
	fi
fi

if ! hash apt-get 2>/dev/null; then
  echo "do-update only works with apt-get, however, this system does not use apt-get."
  exit 2
fi

if ! hash logger 2>/dev/null; then
  echo 'do-update requires logger to log its activity to syslog, please install it using:'
  echo '  sudo apt-get install util-linux'
  exit 3
fi

# Prevent errors and hanging
export TERM=${TERM:-dumb}
export DEBIAN_FRONTEND=noninteractive

clear

echo 'do-update 1.5. 2017-11-01. Copyright (c) Joe Pitt, www.joepitt.co.uk'
echo

echo 'Updating Package List...'
logger '[Info] do-update: Starting Package List Update'
apt-get update -y > /dev/null 2>&1
if [ "$?" == "0" ]; then
  logger '[Info] do-update: Finished Package List Update'
else
  logger -s '[Error] do-update: Package List Update Failed'
  exit 10
fi

echo 'Upgrading Packages...'
logger '[Info] do-update: Starting Package Upgrades'
apt-get upgrade -y > /dev/null 2>&1
if [ "$?" == "0" ]; then
  logger '[Info] do-update: Finished Package Upgrades'
else
  logger -s '[Error] do-update: Package Upgrades Failed'
  exit 11
fi

echo 'Upgrading Distribution...'
logger '[Info] do-update: Starting Distribution Upgrade'
apt-get dist-upgrade -y > /dev/null 2>&1
if [ "$?" == "0" ]; then
  logger '[Info] do-update: Finished Distribution Upgrade'
else
  logger -s '[Error] do-update: Distribution Upgrade Failed'
  exit 12
fi

echo 'Removing Unneeded Packages...'
logger '[Info] do-update: Starting Unneeded Package Removal'
apt-get autoremove -y > /dev/null 2>&1
if [ "$?" == "0" ]; then
  logger '[Info] do-update: Finished Unneeded Package Removal'
else
  logger -s '[Error] do-update: Unneeded Package Removal Failed'
  exit 13
fi

echo 'Deleting Old Packages...'
logger '[Info] do-update: Starting Old Package Deletion'
apt-get autoclean -y > /dev/null 2>&1
if [ "$?" == "0" ]; then
  logger '[Info] do-update: Finished Old Package Deletion'
else
  logger -s '[Error] do-update: Old Package Deletion Failed'
  exit 14
fi


# Determine if reboot is required
if [ -a /var/run/reboot-required ]; then
	if [ "$1" == "-y" ]; then
		echo "Rebooting System..."
		sleep 1
		logger '[Info] do-update: Reboot needed, -y flag set, rebooting now'
		reboot > /dev/null 2>&1
	elif [ "$1" == "-n" ]; then
		echo "Done. Reboot Required!"
		logger '[Notice] do-update: Reboot needed, -n flag set, not rebooting'
	else
		echo -n "Reboot Required! Reboot Now? [yes/no]  "
		read answer
		if [ $answer == "yes" ]; then
			echo "Rebooting System..."
			sleep 1
			logger '[Info] do-update: Reboot needed, user requested reboot, rebooting now'
			reboot > /dev/null 2>&1
		else
			logger '[Notice] do-update: Reboot needed, user declined reboot, not rebooting'
		fi
	fi
else
	logger '[Info] do-update: Completed Successfully (No Reboot Meeded)'
fi
