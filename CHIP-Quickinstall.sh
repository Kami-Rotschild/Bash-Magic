#! /bin/bash
# This is a bash setup/install script mainly useful for CHIP and other Debian based SBC-distros.

SNAPVER=0.15.0
SNAPDIST=armhf
NODEJS=10.x

read -s -r -p "[sudo] password for $USER:" SUDO
echo " "

if [[ "$(echo $SUDO | sudo -S whoami)" != root ]]; then
	echo "Please enter correct password for 'root'!"
	exit
fi

echo " "
read -p "Start Pre-Setup routine? (y/n)" -n 1 INSTALL
echo " "
read -p "Install Snapclient $SNAPVER? (y/n)" -n 1 SNAP
echo " "
read -p "Install (B)ash-Mute-IO / Node-(R)ed / b(o)th / (n)one?" -n 1 IO
echo " "
read -p "Install Dev-Rules? (y/n)" -n 1 DEVRULES
echo " "
read -p "Restart when complete? (y/n)" -n 1 RESTART
echo " "

if [[ "$INSTALL" == [yY] ]];then
	if [[ "$1" != "" ]];then
		USERNAME=$1
		CNAME=$2
	else
		read -p "Please insert new Username:" USERNAME
		read -p "Please insert new Computername:" CNAME
	fi
	read -p "Lock ROOT access locally? (y/n)" -n 1 ROOTING
	echo " "
	read -p "Rename Standar-User to $USERNAME? (y/n)" -n 1 RENAME
	echo " "
	if [[ "$RENAME" == [yY] ]];then
		echo $SUDO | sudo -S pkill -u 1000
		echo $SUDO | sudo -S usermod -l $USERNAME chip
		if [ $? != 0 ]; then
			echo "Failed to rename user!"
			exit
		fi
		echo " "
		echo SUDO | sudo -S usermod -d /home/$USERNAME -m $USERNAME
		echo "Password for $USERNAME"
		echo SUDO | sudo -S passwd $USERNAME
	fi
	
	echo "Password for root"
	echo SUDO | sudo -S passwd root
	
	if [[ "$ROOTING" == [yY] ]];then
		echo SUDO | sudo -S passwd -l root
	fi
	echo " "
	echo "Disabling bluetooth"
	echo SUDO | sudo -S systemctl stop bluetooth
	echo SUDO | sudo -S systemctl disable bluetooth

	echo "Disabling unnecessary log writing"
	echo SUDO | sudo -S ed -i '/daemon.\*;mail.\*;\\/,$d' /etc/rsyslog.conf
	echo SUDO | sudo -S service rsyslog restart
	echo SUDO | sudo -S loginctl enable-linger $USERNAME

	echo "Changing to /var to tmpfs"
	echo SUDO | sudo -S echo "tmpfs    /tmp    tmpfs    defaults,noatime,nosuid,size=100m    0 0" >> /etc/fstab
	echo SUDO | sudo -S echo "tmpfs    /var/tmp    tmpfs    defaults,noatime,nosuid,size=30m    0 0" >> /etc/fstab
	echo SUDO | sudo -S echo "tmpfs    /var/log    tmpfs    defaults,noatime,nosuid,mode=0755,size=100m    0 0" >> /etc/fstab
	echo SUDO | sudo -S echo "tmpfs    /var/spool/mqueue    tmpfs    defaults,noatime,nosuid,mode=0700,gid=12,size=30m    0 0" >> /etc/fstab

	echo "Changing network accessability"
	echo SUDO | sudo -S echo $CNAME > /etc/hostname
	echo SUDO | sudo -S sed -i "s/chip/$CNAME/" /etc/hosts
	echo SUDO | sudo -S sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
	echo "Updating obsolete NTC apt-database to JFpossibilities"
	echo SUDO | sudo -S sed -i 's/opensource.nextthing.co/chip.jfpossibilities.com/' /etc/apt/sources.list

	echo SUDO | sudo -S apt update -y
	echo SUDO | sudo -S apt upgrade -y
fi

if [[ "$SNAP" == [yY] ]];then
	wget -P /tmp https://github.com/badaix/snapcast/releases/download/v$SNAPVER/snapclient_"$SNAPVER"_"$SNAPDIST".deb
	echo SUDO | sudo -S dpkg -i /tmp/snapclient_"$SNAPVER"_"$SNAPDIST".deb
	echo SUDO | sudo -S apt -f install -y --force-yes
fi

if [[ "$IO" == [ORBorb] ]];then
	apt install smbclient build-essential -y
	if [[ "$IO" = [RroO] ]];then
		curl -sL https://deb.nodesource.com/setup_$NODEJS | bash -
		apt install -y nodejs
		npm install -g --unsafe-perm node-red
		echo SUDO | sudo -S cp Node-Red/node-red.service /etc/systemd/system/node-red.service
		systemctl enable node-red
	fi
	if [[ "$IO" == [OobB] ]];then
		echo SUDO | sudo -S cp AutoMute/automute-chip.sh /root/automute-chip.sh
		echo SUDO | sudo -S cp AutoMute/automute-chip.service /etc/systemd/system/automute-chip.service
		echo SUDO | sudo -S systemctl enable automute-chip
		echo SUDO | sudo -S systemctl start automute-chip
	fi
fi

if [[ "$DEVRULES" == [yY] ]];then
	echo SUDO | sudo -S GPIO-Dev-Rules/setup_gpio.sh $USERNAME
fi

echo SUDO | sudo -S apt autoremove -y

if [[ "$RESTART" == [yY] ]];then
	reboot now
fi

echo "DONE!"
exit
