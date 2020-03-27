#!/bin/bash

# Pass argument "nightly" to use nightly build instead of release build.
telegrafbuild=$1

if [[ -z $telegrafbuild ]]; then
releasebuild=1;
else
        if [[ $telegrafbuild -eq "nightly" ]]; then
                 releasebuild=0
        else
                 releasebuild=1
        fi
fi
echo $releasebuild


echo "**********Starting Setup **********"
#dpkg-query -l docker.io
PKG_DOCKER=$(dpkg-query -W --showformat='${Status}\n' docker.io|grep "install ok installed")
echo Package Docker: $PKG_DOCKER
if [ "" == "$PKG_DOCKER" ];
then
  echo "***********Installing Docker***************"
  sudo apt-get install docker.io -y
else
  echo "Docker already installed"	
fi

echo "************Installing Telegraf***********"
cd $HOME
#Add influx repo
sudo rm -rf /etc/apt/sources.list.d/influxdb.list
sudo wget -qO- https://repos.influxdata.com/influxdb.key | sudo apt-key add -
source /etc/lsb-release
echo "Adding telegraf repo"
sudo echo "deb https://repos.influxdata.com/${DISTRIB_ID,,} ${DISTRIB_CODENAME} stable"
sudo echo "deb https://repos.influxdata.com/${DISTRIB_ID,,} ${DISTRIB_CODENAME} stable" | sudo tee /etc/apt/sources.list.d/influxdb.list


#sudo dpkg-query -l telegraf
#dpkg-query -l telegraf
PKG_TELEGRAF=$(dpkg-query -W --showformat='${Status}\n' telegraf|grep "install ok installed")
echo Package telegraf: $PKG_TELEGRAF
if [ "" == "$PKG_TELEGRAF" ];
then
  echo "***********Installing telegraf***************"
  if [[ $releasebuild == 1 ]]
  then
	echo "*** Telegraf Release Build being installed"
	sudo apt-get update && sudo apt-get install telegraf
  else  
	echo "*** Telegraf Nightly build being installed"
	wget https://dl.influxdata.com/telegraf/nightlies/telegraf_nightly_amd64.deb
	sudo dpkg -i telegraf_nightly_amd64.deb
  fi
else
  echo "Telegraf already installed"
fi


echo "********* Firewall rule for Grafana port **********"
sudo ufw allow 3000/tcp
sudo ufw reload

echo "****** copying telegraf.conf sample for SQL, original conf renamed to /etc/telegraf/telegraf_original.conf  ****/"
sudo mv /etc/telegraf/telegraf.conf /etc/telegraf/telegraf_original.conf 
sudo cp $HOME/sqldbmonitoring/telegraf/telegraf.conf /etc/telegraf/telegraf.conf 
sudo chown root:root /etc/telegraf/telegraf.conf 
sudo chmod 644 /etc/telegraf/telegraf.conf

echo "********Pulling grafana container ****************"
cd $HOME/sqldbmonitoring/grafana
sudo ./rungrafana.sh


