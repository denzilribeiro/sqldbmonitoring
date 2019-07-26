#!/bin/bash

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
wget https://dl.influxdata.com/telegraf/nightlies/telegraf_nightly_amd64.deb
dpkg-query -l telegraf


if [ $? -ne 0 ]
then
  echo "***********Installing telegraf***************"
  sudo dpkg -i telegraf_nightly_amd64.deb
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


