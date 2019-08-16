# Azure SQL Database / Managed Instance monitoring

## VM Setup

Create an Ubuntu VM in a new or an existing resource group with a data disk and mount the attached data disk in the Linux OS. Other Linux distros will work as well, but commands may need to be adjusted accordingly.

**Example with Az CLI**

 -  Create a resource group with the [az group create](https://docs.microsoft.com/en-us/cli/azure/group) command. Preferably, use the region where the monitored resources are located.
 - Create the Ubuntu VM with [az vm create](https://docs.microsoft.com/en-us/cli/azure/vm?view=azure-cli-latest#az-vm-create) : Sample CLI command here creates a VM with SSH authentication, as well as with an additional 1TB data disk which will be used to store the monitoring data. If you already have an SSH key pair, you can provide the public key here using the --ssh-key-values argument
```
az vm create --resource-group _ResourceGroupName_ --name _VmName_ --image UbuntuLTS --size _Standard_DS2_v2_ --generate-ssh-keys –nsg-rule SSH --data-disk-sizes-gb 1024
```
 - [Connect](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/ssh-from-windows#connect-to-your-vm) to the VM and [mount the new disk to the VM.](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/attach-disk-portal#connect-to-the-linux-vm-to-mount-the-new-disk)

## Clone repo
The repo includes grafana dashboards for Azure SQL Database and Managed instances, and setup scripts for influxdb, telegraf and grafana.
```
cd $HOME
sudo apt-get install git
git clone https://github.com/denzilribeiro/sqldbmonitoring.git
```

## Setup
Setup will install docker.io, will install the telegraf nightly build and configure the firewall to open up port 3000 required for Grafana and pull and start the Grafana container.
```
cd $HOME/sqldbmonitoring
./monitoringsetup.sh
```

## Install, Configure and start InfluxDB
Assuming you have mounted a separate data drive as specified in the Setup VM portion , edit the runinfluxdb.sh file and modify the INFLUXDB_HOST_DIRECTORY variable to point to the directory where you want the InfluxDB volume to be mounted, if it is something other than the default of /data/influxdb.
```
cd $HOME/sqlmimonitoring/influxdb`  
sudo vi runinfluxdb.sh`
```
Pull the docker image and start InfluxDB
```
cd $HOME/sqlmimonitoring/influxdb  
sudo ./runinfluxdb.sh
```

## Create Logins for each Managed Instance or SQL DB being monitored
For Managed Instance
```
USE master;  
CREATE LOGIN telegraf WITH PASSWORD = N'StrongPassword1!', CHECK_POLICY = ON;  
GRANT VIEW SERVER STATE TO telegraf;  
GRANT VIEW ANY DEFINITION TO telegraf;
```
For SQL DB create a database scoped user for each database being monitored.
```
CREATE USER [telegraf] WITH PASSWORD = N'Mystrongpassword1!';
GO
GRANT VIEW DATABASE STATE TO [telegraf];
GO
```

## Edit the telegraf configuration file
Modify the /etc/telegraf.conf with the options specified [here](https://github.com/influxdata/telegraf/tree/master/plugins/inputs/sqlserver)

Edit the /etc/telegraf.conf one string per connection string.

**Note:** For **Azure SQL Database**, you would need one connection string per database you are monitoring specifying the right database name and not master. An example snippet is below
```
[[inputs.sqlserver]]  
servers = ["Server=server1.xxx.database.windows.net;Port=1433;User Id=telegraf;Password=Mystringpassword1!;database=master;app name=telegraf;"  
,"Server=server2.xxx.database.windows.net;Port=1433;User Id=telegraf;Password=Mystrongpassword1!;database=myazuredb;app name=telegraf;"]  

query_version = 2
azuredb=true
```
By default all the collectors are enabled. If you copy the sample telegraf.conf the Schedulers and SqlRequests collector are excluded as they are chattier than other collectors. You can control what collectors to exclude by including them in the excluded array in the conf file
```
exclude_query = [ 'Schedulers' , 'SqlRequests']
```
If the influx DB docker container is on the same VM then the section below doesn’t have to change, if it is on another machine or non-default port, the url would have to be updated accordingly.
```
urls = ["[http://127.0.0.1:8086](http://127.0.0.1:8086/)"]  
database = "telegraf"
```

**Note:**
 - Port for managed instance with public endpoint is 3342
 - If influxDB is hosted on a different VM have to modify the url for outputs.influxdb
 - Default polling interval is 10 seconds, if you want to change that have to add /change the Agent Interval value.

## Start the telegraf service

```
sudo systemctl start telegraf
sudo systemctl status telegraf
```
To Troubleshoot any failures you can look at the log entries
```
sudo journalctl -u telegraf
```

## Create Telegraf database and retention policy
We want to set a retention policy in influxdb based on how long data needs to be kept.
```
sudo docker exec -it influxdb influx
use telegraf;  
show retention policies;
create retention policy retain30days on telegraf duration 30d replication 1 default;  
quit
```

## Configure grafana data source and dashboards
Dashboards are located here:

 - [Azure SQL Database Dashboards](https://github.com/denzilribeiro/sqldbmonitoring/tree/master/dashboards/azuresqldb)
 - [Azure SQL Managed Instance Dashboards](https://github.com/denzilribeiro/sqldbmonitoring/tree/master/dashboards/azuresqlmi)

In Grafana, create the data source for InfluxDB, and import respective dashboards

 - Browse to your Grafana instance - [http://[GRAFANA_IP_ADDRESS_OR_SERVERNAME]:3000](http://[GRAFANA_IP_ADDRESS_OR_SERVERNAME]:3000)

- Add a data source for InfluxDB. Detailed instructions are at in the [grafana data source docs](http://docs.grafana.org/features/datasources/influxdb/)

		Name: influxdb-01  
		Type: InfluxDB  
		URL: http://[INFLUXDB_HOSTNAME_OR_IP_ADDRESS]:8086. The default of http://localhost:8086 works if Grafana and InfluxDB are on the same machine; make sure to explicitly enter this URL in the field.  
		Database: telegraf
		Click “Save & Test”. You should see the message “Data source is working”.


- Download Grafana dashboard JSON definitions from the repo [SQLDB dashboards](https://github.com/denzilribeiro/sqldbmonitoring/tree/master/dashboards/azuresqldb) folder or [SQL Managed Instance Dashboards](https://github.com/denzilribeiro/sqldbmonitoring/tree/master/dashboards/azuresqlmi) for all the dashboards, and then [import](http://docs.grafana.org/reference/export_import/#importing-a-dashboard) them into Grafana. When importing each dashboard, make sure to use the dropdown labeled _InfluxDB-01_ to select the data source created in the previous step.


