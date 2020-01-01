#!/bin/bash
# do-update v1.6 (2020-01-01)
# https://www.joepitt.co.uk/Project/do-update/
# Copyright (C) 2020  Joe Pitt

# This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
# License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
# version.

# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
# warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

# You should have received a copy of the GNU General Public License along with this program. If not, see
# <https://www.gnu.org/licenses/>.

echo 'do-update v1.6 (2020-01-01)  Copyright (C) 2020  Joe Pitt'
echo 'This program comes with ABSOLUTELY NO WARRANTY.'
echo 'This is free software, and you are welcome to redistribute it under certain conditions; see ' \
' https://www.gnu.org/licenses/gpl-3.0.txt for details.'

# Check running as root
if [ "$(id -u)" != "0" ]; then
	if hash sudo 2>/dev/null; then
		# Self-Elevate to root
		sudo $0 $@
		exit $?
	else
		echo "do-update must be run as root, however, sudo is not installed so cannot self elevate."
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

# Prevent apt from prompting for user input
export TERM=${TERM:-dumb}
export DEBIAN_FRONTEND=noninteractive

echo
echo 'Updating Package List...'
logger '[Info] do-update: Starting Package List Update'
apt-get update -y >/dev/null 2>&1
if [ "$?" == "0" ]; then
	logger '[Info] do-update: Finished Package List Update'
else
	logger -s '[Error] do-update: Package List Update Failed'
	exit 10
fi

echo 'Upgrading Packages...'
logger '[Info] do-update: Starting Package Upgrades'
apt-get upgrade -y >/dev/null 2>&1
if [ "$?" == "0" ]; then
	logger '[Info] do-update: Finished Package Upgrades'
else
	logger -s '[Error] do-update: Package Upgrades Failed'
	exit 11
fi

echo 'Upgrading Distribution...'
logger '[Info] do-update: Starting Distribution Upgrade'
apt-get dist-upgrade -y >/dev/null 2>&1
if [ "$?" == "0" ]; then
	logger '[Info] do-update: Finished Distribution Upgrade'
else
	logger -s '[Error] do-update: Distribution Upgrade Failed'
	exit 12
fi

echo 'Removing Unneeded Packages...'
logger '[Info] do-update: Starting Unneeded Package Removal'
apt-get autoremove -y >/dev/null 2>&1
if [ "$?" == "0" ]; then
	logger '[Info] do-update: Finished Unneeded Package Removal'
else
	logger -s '[Error] do-update: Unneeded Package Removal Failed'
	exit 13
fi

echo 'Deleting Old Packages...'
logger '[Info] do-update: Starting Old Package Deletion'
apt-get autoclean -y >/dev/null 2>&1
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
		logger '[Info] do-update: Reboot needed, -y flag set, rebooting now'
		sleep 1
		reboot >/dev/null 2>&1
	elif [ "$1" == "-n" ]; then
		echo "Done. Reboot Required!"
		logger '[Notice] do-update: Reboot needed, -n flag set, not rebooting'
	else
		echo -n "Reboot Required! Reboot Now? [yes/no]  "
		read answer
		if [ $answer == "yes" ]; then
			echo "Rebooting System..."
			logger '[Info] do-update: Reboot needed, user requested reboot, rebooting now'
			sleep 1
			reboot >/dev/null 2>&1
		else
			logger '[Notice] do-update: Reboot needed, user declined reboot, not rebooting'
		fi
	fi
else
	logger '[Info] do-update: Completed Successfully (No Reboot Meeded)'
fi
