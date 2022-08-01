#!/bin/bash

#We use the grafana image that Grafana Labs provides http://docs.grafana.org/installation/docker/
# If you wish to modify the port that Grafana runs on, you can do that here.
GRAFANA_HOST_DIRECTORY="/data/grafana"

sudo docker run --user root  --detach -p 3000:3000 --net=host --restart=always \
	-v $GRAFANA_HOST_DIRECTORY:/var/lib/grafana \
	-e "GF_INSTALL_PLUGINS=grafana-piechart-panel,savantly-heatmap-panel" \
	--name grafana grafana/grafana



