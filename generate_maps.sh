#!/bin/bash

# Download Finland if no data is provided
if [ ! -f /osm-data/data.osm.pbf ]; then
		echo "WARNING: No import file at /data.osm.pbf, so importing Finland as default..."
		wget -nv http://download.geofabrik.de/europe/finland-latest.osm.pbf -O /osm-data/data.osm.pbf
fi

cd /home/renderer


# TAMPERE
#################
#################

# Extract region out of Finland OSM file
osmosis --read-pbf file=/osm-data/data.osm.pbf --bounding-box left=22.80 bottom=61.00 right=25.00 top=62.00 --write-pbf region.osm.pbf

# Split the osm file to smaller pieces
java -Xmx4000m -jar splitter.jar region.osm.pbf\
 --description="Tampere Region"\
 --precomp-sea=sea.zip\
 --geonames-file=cities.zip\
 --max-areas=4096\
 --max-nodes=1000000\
 --mapid=48730001\
 --status-freq=2\
 --keep-complete=true

# Fix the names in the template.args file descriptions, MAX 20 CHARACTERS
python3 fix_names.py TK_MTB_Tampere

# Create the gmapsupp map file, NOTE THE MAPNAME HAS TO UNIQUE, FAMILY ID IS ALSO UNIQUE
java -Xmx6000m -jar mkgmap.jar\
 --max-jobs\
 --gmapsupp\
 --latin1\
 --tdbfile\
 --mapname=88880001\
 --description="OpenStreetMap-pohjainen MTB-kartta, Tampereen alue"\
 --family-id=8888\
 --series-name="OSM MTB Suomi"\
 --style-file=TK/ \
 --cycle-map\
 --precomp-sea=sea.zip\
 --generate-sea\
 --bounds=bounds.zip\
 --remove-ovm-work-files\
 -c template.args \
 TK_Tampere.typ

# copy the map file to folder that is mapped to local host
mv gmapsupp.img /ready_maps/tk_tre.img

# Clean the directory
rm -f  osmmap.* *.img *.pbf osmmap_license.txt template* densities* areas*


# HELSINKI
#################
#################

# Extract region out of Finland OSM file
osmosis --read-pbf file=/osm-data/data.osm.pbf --bounding-box left=24.37 bottom=60.12 right=25.28 top=60.41 --write-pbf region.osm.pbf

# Split the osm file to smaller pieces
java -Xmx4000m -jar splitter.jar region.osm.pbf\
 --description="Helsinki Region"\
 --precomp-sea=sea.zip\
 --geonames-file=cities.zip\
 --max-areas=4096\
 --max-nodes=1000000\
 --mapid=48730001\
 --status-freq=2\
 --keep-complete=true

# Fix the names in the template.args file descriptions, MAX 20 CHARACTERS
python3 fix_names.py TK_MTB_Helsinki

# Create the gmapsupp map file, NOTE THE MAPNAME HAS TO UNIQUE, FAMILY ID IS ALSO UNIQUE
java -Xmx6000m -jar mkgmap.jar\
 --max-jobs\
 --gmapsupp\
 --latin1\
 --tdbfile\
 --mapname=88890001\
 --description="OpenStreetMap-pohjainen MTB-kartta, Helsingin alue"\
 --family-id=8889\
 --series-name="OSM MTB Suomi"\
 --style-file=TK/ \
 --cycle-map\
 --precomp-sea=sea.zip\
 --generate-sea\
 --bounds=bounds.zip\
 --remove-ovm-work-files\
 -c template.args \
 TK_Helsinki.typ

# copy the map file to folder that is mapped to local host
mv gmapsupp.img /ready_maps/hki_tre.img

# Clean the directory
rm -f  osmmap.* *.img *.pbf osmmap_license.txt template* densities* areas*
