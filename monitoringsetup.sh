#!/bin/bash
telegrafbuild=$1

if [[ $telegrafbuild -eq "nightly" ]]; then
 releasebuild=0
else
 releasebuild=1
fi


echo "**********Starting Setup **********"
dpkg-query -l docker.io

if [ $? -ne 0 ]
then
  echo "***********Installing Docker***************"
  sudo apt-get install docker.io -y
else
  echo "Docker already installed"	
fi

echo "************Installing Telegraf Nightly***********"
cd $HOME

sudo apt search telegraf | grep telegraf
if [ $? -ne 0 ]
then
	sudo wget -qO- https://repos.influxdata.com/influxdb.key | sudo apt-key add -
	sudo source /etc/lsb-release
	sudo echo "deb https://repos.influxdata.com/${DISTRIB_ID,,} ${DISTRIB_CODENAME} stable" | sudo tee /etc/apt/sources.list.d/influxdb.list
fi

dpkg-query -l telegraf
if [ $? -ne 0 ]
then
  echo "***********Installing telegraf***************"
  if [ releasebuild -eq 1]
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

echo "****** copying telegraf.conf sample for SQL, original conf renamed to /etc/telegraf_original.conf  ****/"
sudo mv /etc/telegraf/telegraf.conf /etc/telegraf/telegraf_original.conf 
sudo cp $HOME/sqldbmonitoring/telegraf/telegraf.conf /etc/telegraf/telegraf.conf 
sudo chown root:root /etc/telegraf/telegraf.conf 
sudo chmod 644 /etc/telegraf/telegraf.conf

echo "********Pulling grafana containger ****************"
cd $HOME/sqldbmonitoring/grafana
sudo ./rungrafana.sh


