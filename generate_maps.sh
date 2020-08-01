#!/bin/bash

function create_map () {
	# Extract region out of Finland OSM file
	osmosis --read-pbf file=/osm-data/data.osm.pbf --bounding-box left=$1 bottom=$2 right=$3 top=$4 --write-pbf region.osm.pbf

	# Split the osm file to smaller pieces
	java -Xmx4000m -jar splitter.jar region.osm.pbf\
	--description="$6"\
	--precomp-sea=sea.zip\
	--geonames-file=cities.zip\
	--max-areas=4096\
	--max-nodes=1000000\
	--mapid=${8}\
	--status-freq=2\
	--keep-complete=true

	# Fix the names in the template.args file descriptions, MAX 20 CHARACTERS
	python3 fix_names.py $7

	# Create the gmapsupp map file, NOTE THE MAPNAME HAS TO UNIQUE, FAMILY ID IS ALSO UNIQUE
	java -Xmx6000m -jar mkgmap.jar\
	--max-jobs\
	--gmapsupp\
	--latin1\
	--tdbfile\
	--mapname=${8}\
	--description="$7"\
	--family-id=8888\
	--product-id=1\
	--series-name="OSM MTB Suomi"\
	--family-name="OSM MTB Suomi"\
	--area-name="OSM MTB Suomi"\
	--style-file=$5/ \
	--cycle-map\
	--precomp-sea=sea.zip\
	--generate-sea\
	--bounds=bounds.zip\
	--remove-ovm-work-files\
	${10} \
	-c template.args \
	$7.typ


	# copy the map file to folder that is mapped to local host
	mv gmapsupp.img /ready_maps/$9

	# Clean the directory
	rm -f  osmmap.* *.img *.pbf osmmap_license.txt template* densities* areas*
}

# Download Finland if no data is provided
if [ ! -f /osm-data/data.osm.pbf ]; then
		echo "WARNING: No import file at /data.osm.pbf, so importing Finland as default..."
		wget -nv http://download.geofabrik.de/europe/finland-latest.osm.pbf -O /osm-data/data.osm.pbf
fi

cd /home/renderer

create_map 22.80 61.00 25.00 62.20 TK "Tampere region" TK_Tampere 88880001 tk_tre.img
create_map 24.37 60.12 25.28 60.41 TK "Helsinki region" TK_Helsinki 88890002 tk_hki.img
create_map 24.50 64.70 26.20 65.25 TK "Oulu region" TK_Oulu 88900003 tk_oulu.img
create_map 24.98314 60.87659 26.28208 61.37907 TK "Lahti region" TK_Lahti 88910004 tk_lahti.img
create_map 21.20 60.70 23.00 61.70 TK "Eura Pori Rauma region" TK_Eura 88920005 tk_eura.img
create_map 27.30 62.70 28.10 63.20 TK "Kuopio region" TK_Kuopio 88930006 tk_kuopio.img
create_map 29.02 65.36 29.74 65.58 TK "Hossa region" TK_Hossa 88950008 tk_hossa.img
create_map 27.41 65.52 27.91 65.81 TK "Syote region" TK_Syote 88960009 tk_syote.img
create_map 23.35 67.39 25.12 68.42 TK "Levi Ylläs" TK_Yllas 88970010 tk_yllas.img
create_map 28.757 62.006 31.058 63.198 TK "Joensuu region" TK_Joensuu 89080018 tk_joensuu.img 

create_map 21.00 59.75 31.60 70.08 TK "Finland" TK_Finland 88940007 tk_finland.img


create_map 22.80 61.00 25.00 62.20 TK_pathsonly "Tampere region" TK_Tampere 88980011 tk_tre_paths.img "--transparent --draw-priority=30"
create_map 24.37 60.12 25.28 60.41 TK_pathsonly "Helsinki region" TK_Helsinki 88990012 tk_hki_paths.img "--transparent --draw-priority=30"
create_map 24.50 64.70 26.20 65.25 TK_pathsonly "Oulu region" TK_Oulu 89000013 tk_oulu_paths.img "--transparent --draw-priority=30"
create_map 24.98314 60.87659 26.28208 61.37907 TK_pathsonly "Lahti region" TK_Lahti 89010014 tk_lahti_paths.img "--transparent --draw-priority=30"
create_map 21.20 60.70 23.00 61.70 TK_pathsonly "Eura Pori Rauma region" TK_Eura 89020015 tk_eura_paths.img "--transparent --draw-priority=30"
create_map 27.30 62.70 28.10 63.20 TK_pathsonly "Kuopio region" TK_Kuopio 89030016 tk_kuopio_paths.img "--transparent --draw-priority=30"
create_map 29.02 65.36 29.74 65.58 TK_pathsonly "Hossa region" TK_Hossa 89040018 tk_hossa_paths.img "--transparent --draw-priority=30"
create_map 27.41 65.52 27.91 65.81 TK_pathsonly "Syote region" TK_Syote 89050019 tk_syote_paths.img "--transparent --draw-priority=30"
create_map 23.35 67.39 25.12 68.42 TK_pathsonly "Levi Ylläs" TK_Yllas 89060020 tk_yllas_paths.img "--transparent --draw-priority=30"
create_map 28.757 62.006 31.058 63.198 TK_pathsonly "Joensuu region" TK_Joensuu 89090019 tk_joensuu_paths.img "--transparent --draw-priority=30"

create_map 21.00 59.75 31.60 70.08 TK_pathsonly "Finland" TK_Finland 89070017 tk_finland_paths.img "--transparent --draw-priority=30"


 