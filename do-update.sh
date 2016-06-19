#!/bin/bash
# This work is licensed under the Creative Commons
# Attribution-NonCommercial-ShareAlike 4.0 International License. To view a
# copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.
export TERM=${TERM:-dumb}
clear
echo 'do-update 1.3. 2016-01-06. Copyright (c) Joe Pitt, www.joepitt.co.uk'
sudo echo
echo 'Updating Package List...'
sudo apt-get update -y > /dev/null 2>&1
echo 'Upgrading Packages...'
sudo apt-get upgrade -y > /dev/null 2>&1
echo 'Upgrading Distribution...'
sudo apt-get dist-upgrade -y > /dev/null 2>&1
echo 'Removing Unneeded Packages...'
sudo apt-get autoremove -y > /dev/null 2>&1

reboot=`file /var/run/reboot-required | grep "ERROR" | wc -l`
if [ $reboot == "0" ]; then
	if [ "$1" == "-y" ]; then
		echo "Rebooting System..."
		sleep 1
		sudo reboot > /dev/null 2>&1
	elif [ "$1" == "-n" ]; then
		echo "Done. Reboot Required!"
	else
		echo -n "Reboot Required! Reboot Now? [yes/no]  "
		read answer
		if [ $answer == "yes" ]; then
				echo "Rebooting System..."
				sleep 1
				sudo reboot > /dev/null 2>&1
		fi
	fi
fi
