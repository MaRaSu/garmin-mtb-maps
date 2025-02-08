#!/bin/bash

function create_map() {
	# Extract region out of Finland OSM file
	osmosis --read-pbf file=/data/data.osm.pbf --bounding-box left=$1 bottom=$2 right=$3 top=$4 --write-pbf region.osm.pbf

	# Split the osm file to smaller pieces
	java -Xmx4000m -jar splitter.jar region.osm.pbf --description="$6" \
		--precomp-sea=sea.zip --geonames-file=cities.zip --max-areas=4096 --max-nodes=1000000 --mapid=${9} \
		--status-freq=2 --keep-complete=true

	# Fix the names in the template.args file descriptions, MAX 20 CHARACTERS
	python3 fix_names.py $8

	# Create the gmapsupp map file, NOTE THE MAPNAME HAS TO BE UNIQUE, FAMILY ID IS ALSO UNIQUE
	java -Xmx6000m -jar mkgmap.jar --max-jobs --gmapsupp --latin1 --tdbfile --mapname=${9} \
		--description="$8" \
		--family-id=8888 --product-id=1 --series-name="OSM MTB Suomi" \
		--family-name="OSM MTB Suomi" \
		--area-name="OSM MTB Suomi" \
		--style-file=$5/ \
		--cycle-map --precomp-sea=sea.zip --generate-sea --bounds=bounds.zip --remove-ovm-work-files ${11} \
		-c template.args \
		$7.typ

	# copy the map file to folder that is mapped to local host
	mv gmapsupp.img /data/${10}

	# Clean the directory
	rm -f osmmap.* *.img *.pbf osmmap_license.txt template* densities* areas*
}

# Download Finland if no data is provided
if [ ! -f /data/data.osm.pbf ]; then
	echo "WARNING: No import file at /data.osm.pbf, so importing Finland as default..."
	wget -nv http://download.geofabrik.de/europe/finland-latest.osm.pbf -O /data/data.osm.pbf
fi

cd /home/renderer

create_map 21.00 59.75 31.60 70.08 TK "Finland" TK_Finland_v2 TK_Finland 88940007 tk_finland.img
# create_map 21.00 59.75 31.60 70.08 TK_pathsonly "Finland" TK_Tampere_v2 TK_Finland_polut 89070017 tk_finland_paths.img "--transparent --draw-priority=30"
