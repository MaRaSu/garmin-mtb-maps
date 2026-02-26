#!/bin/bash

# Multi-layer Trailmap generation for modern Garmin devices
# Processes complete OSM data file (no bounding box extraction)
# Creates three layers: routing (priority=1), bottom (priority=90), main (priority=91)

set -e

# Expects /data/data.osm.pbf to exist
if [ ! -f /data/data.osm.pbf ]; then
	echo "ERROR: No import file at /data/data.osm.pbf"
	exit 1
fi

cd /home/renderer

echo "=========================================="
echo "Starting Trailmap Multi-Layer Generation"
echo "=========================================="

# LAYER 1: Routing layer (draw-priority=1, mapid starts at 80010000)
echo ""
echo "=== Processing Routing Layer ==="
echo "Splitting OSM data for routing layer..."
java -Xmx4000m -jar splitter.jar /data/data.osm.pbf \
	--output=pbf \
	--output-dir=split_routing \
	--description="Finland Routing" \
	--precomp-sea=sea.zip \
	--geonames-file=cities.zip \
	--max-areas=4096 \
	--max-nodes=1000000 \
	--mapid=80010000 \
	--status-freq=2 \
	--keep-complete=true

echo "Renaming template.args for routing layer..."
mv split_routing/template.args split_routing/trailmap_routing_v1-finland.args

echo "Compiling routing layer..."
java -Xmx6000m -jar mkgmap.jar \
	--location-autofill=is_in \
	--draw-priority=1 \
	--code-page=1252 \
	--latin1 \
	--family-id=8800 \
	--product-id=1 \
	--mapname=80000001 \
	--style-file=trailmap_mtb_routing_v1/ \
	--bounds=bounds.zip \
	--net \
	--route \
	--ignore-turn-restrictions \
	--index \
	--output-dir=compiled_routing \
	-c split_routing/trailmap_routing_v1-finland.args

# LAYER 2: Bottom layer (draw-priority=90, mapid starts at 80020000)
echo ""
echo "=== Processing Bottom Layer ==="
echo "Splitting OSM data for bottom layer..."
java -Xmx4000m -jar splitter.jar /data/data.osm.pbf \
	--output=pbf \
	--output-dir=split_bottom \
	--description="Finland Bottom" \
	--precomp-sea=sea.zip \
	--geonames-file=cities.zip \
	--max-areas=4096 \
	--max-nodes=1000000 \
	--mapid=80020000 \
	--status-freq=2 \
	--keep-complete=true

echo "Renaming template.args for bottom layer..."
mv split_bottom/template.args split_bottom/trailmap_bottom_v1-finland.args

echo "Compiling bottom layer..."
java -Xmx6000m -jar mkgmap.jar \
	--draw-priority=90 \
	--code-page=1252 \
	--min-size-polygon=12 \
	--latin1 \
	--family-id=8800 \
	--product-id=1 \
	--mapname=80000002 \
	--style-file=trailmap_mtb_bottom_v1/ \
	--precomp-sea=sea.zip \
	--generate-sea \
	--bounds=bounds.zip \
	--output-dir=compiled_bottom \
	-c split_bottom/trailmap_bottom_v1-finland.args

# LAYER 3: Main layer (draw-priority=91, transparent, mapid starts at 80030000)
echo ""
echo "=== Processing Main Layer ==="
echo "Splitting OSM data for main layer..."
java -Xmx4000m -jar splitter.jar /data/data.osm.pbf \
	--output=pbf \
	--output-dir=split_main \
	--description="Finland Main" \
	--precomp-sea=sea.zip \
	--geonames-file=cities.zip \
	--max-areas=4096 \
	--max-nodes=1000000 \
	--mapid=80030000 \
	--status-freq=2 \
	--keep-complete=true

echo "Renaming template.args for main layer..."
mv split_main/template.args split_main/trailmap_main_v1-finland.args

echo "Compiling main layer..."
java -Xmx6000m -jar mkgmap.jar \
	--draw-priority=91 \
	--transparent \
	--code-page=1252 \
	--latin1 \
	--family-id=8800 \
	--product-id=1 \
	--mapname=80000003 \
	--style-file=trailmap_mtb_main_v1/ \
	--bounds=bounds.zip \
	--output-dir=compiled_main \
	-c split_main/trailmap_main_v1-finland.args

# Delete osmmap overview files from each compiled directory (they have duplicate IDs)
echo ""
echo "=== Removing osmmap overview files ==="
rm -f compiled_routing/osmmap.img compiled_routing/osmmap.mdx compiled_routing/osmmap.tdb compiled_routing/osmmap_mdr.img
rm -f compiled_bottom/osmmap.img compiled_bottom/osmmap.mdx compiled_bottom/osmmap.tdb compiled_bottom/osmmap_mdr.img
rm -f compiled_main/osmmap.img compiled_main/osmmap.mdx compiled_main/osmmap.tdb compiled_main/osmmap_mdr.img
echo "osmmap files removed from all compiled directories"

# MERGE: Use gmt CLI tool to merge all layers
echo ""
echo "=== Merging Layers ==="
echo "Merging all three layers into single map file..."
/home/renderer/bin/gmt \
	-j \
	-f 8800,1 \
	-m "Trailmap MTB Finland" \
	-o /data/trailmap_finland.img \
	compiled_routing/*.img \
	compiled_bottom/*.img \
	compiled_main/*.img \
	trailmap_mtb_v1.typ

# Remove intermediate osmmap files if they exist
rm -f /data/osmmap.img /data/osmmap.mdx /data/osmmap.tdb /data/osmmap_mdr.img

# Cleanup MTB temporary files
echo ""
echo "=== Cleaning up MTB temporary files ==="
rm -rf split_routing split_bottom split_main
rm -rf compiled_routing compiled_bottom compiled_main

echo ""
echo "=========================================="
echo "MTB Trailmap generation completed!"
echo "Output: /data/trailmap_finland.img"
echo "=========================================="

# ==========================================
# WINTER MAP GENERATION
# ==========================================
echo ""
echo "=========================================="
echo "Starting Winter Trailmap Generation"
echo "=========================================="

# WINTER LAYER 1: Routing layer (draw-priority=1, mapid starts at 80010000)
echo ""
echo "=== Processing Winter Routing Layer ==="
echo "Splitting OSM data for winter routing layer..."
java -Xmx4000m -jar splitter.jar /data/data.osm.pbf \
	--output=pbf \
	--output-dir=split_routing \
	--description="Finland Winter Routing" \
	--precomp-sea=sea.zip \
	--geonames-file=cities.zip \
	--max-areas=4096 \
	--max-nodes=1000000 \
	--mapid=80010000 \
	--status-freq=2 \
	--keep-complete=true

echo "Renaming template.args for winter routing layer..."
mv split_routing/template.args split_routing/trailmap_winter_routing_v1-finland.args

echo "Compiling winter routing layer..."
java -Xmx6000m -jar mkgmap.jar \
	--location-autofill=is_in \
	--draw-priority=1 \
	--code-page=1252 \
	--latin1 \
	--family-id=8800 \
	--product-id=1 \
	--mapname=80000001 \
	--style-file=trailmap_winter_routing_v1/ \
	--bounds=bounds.zip \
	--net \
	--route \
	--ignore-turn-restrictions \
	--index \
	--output-dir=compiled_routing \
	-c split_routing/trailmap_winter_routing_v1-finland.args

# WINTER LAYER 2: Bottom layer (draw-priority=90, mapid starts at 80020000)
echo ""
echo "=== Processing Winter Bottom Layer ==="
echo "Splitting OSM data for winter bottom layer..."
java -Xmx4000m -jar splitter.jar /data/data.osm.pbf \
	--output=pbf \
	--output-dir=split_bottom \
	--description="Finland Winter Bottom" \
	--precomp-sea=sea.zip \
	--geonames-file=cities.zip \
	--max-areas=4096 \
	--max-nodes=1000000 \
	--mapid=80020000 \
	--status-freq=2 \
	--keep-complete=true

echo "Renaming template.args for winter bottom layer..."
mv split_bottom/template.args split_bottom/trailmap_winter_bottom_v1-finland.args

echo "Compiling winter bottom layer..."
java -Xmx6000m -jar mkgmap.jar \
	--draw-priority=90 \
	--code-page=1252 \
	--min-size-polygon=12 \
	--latin1 \
	--family-id=8800 \
	--product-id=1 \
	--mapname=80000002 \
	--style-file=trailmap_winter_bottom_v1/ \
	--precomp-sea=sea.zip \
	--generate-sea \
	--bounds=bounds.zip \
	--output-dir=compiled_bottom \
	-c split_bottom/trailmap_winter_bottom_v1-finland.args

# WINTER LAYER 3: Main layer (draw-priority=91, transparent, mapid starts at 80030000)
echo ""
echo "=== Processing Winter Main Layer ==="
echo "Splitting OSM data for winter main layer..."
java -Xmx4000m -jar splitter.jar /data/data.osm.pbf \
	--output=pbf \
	--output-dir=split_main \
	--description="Finland Winter Main" \
	--precomp-sea=sea.zip \
	--geonames-file=cities.zip \
	--max-areas=4096 \
	--max-nodes=1000000 \
	--mapid=80030000 \
	--status-freq=2 \
	--keep-complete=true

echo "Renaming template.args for winter main layer..."
mv split_main/template.args split_main/trailmap_winter_main_v1-finland.args

echo "Compiling winter main layer..."
java -Xmx6000m -jar mkgmap.jar \
	--draw-priority=91 \
	--transparent \
	--code-page=1252 \
	--latin1 \
	--family-id=8800 \
	--product-id=1 \
	--mapname=80000003 \
	--style-file=trailmap_winter_main_v1/ \
	--bounds=bounds.zip \
	--output-dir=compiled_main \
	-c split_main/trailmap_winter_main_v1-finland.args

# Delete osmmap overview files from each compiled directory
echo ""
echo "=== Removing winter osmmap overview files ==="
rm -f compiled_routing/osmmap.img compiled_routing/osmmap.mdx compiled_routing/osmmap.tdb compiled_routing/osmmap_mdr.img
rm -f compiled_bottom/osmmap.img compiled_bottom/osmmap.mdx compiled_bottom/osmmap.tdb compiled_bottom/osmmap_mdr.img
rm -f compiled_main/osmmap.img compiled_main/osmmap.mdx compiled_main/osmmap.tdb compiled_main/osmmap_mdr.img
echo "osmmap files removed from all compiled directories"

# MERGE: Winter map
echo ""
echo "=== Merging Winter Layers ==="
echo "Merging all three winter layers into single map file..."
/home/renderer/bin/gmt \
	-j \
	-f 8800,1 \
	-m "Trailmap Winter Finland" \
	-o /data/trailmap_winter_finland.img \
	compiled_routing/*.img \
	compiled_bottom/*.img \
	compiled_main/*.img \
	trailmap_winter_v1.typ

# Remove intermediate osmmap files if they exist
rm -f /data/osmmap.img /data/osmmap.mdx /data/osmmap.tdb /data/osmmap_mdr.img

# Cleanup winter temporary files
echo ""
echo "=== Cleaning up winter temporary files ==="
rm -rf split_routing split_bottom split_main
rm -rf compiled_routing compiled_bottom compiled_main

echo ""
echo "=========================================="
echo "All trailmap generation completed successfully!"
echo "Output: /data/trailmap_finland.img"
echo "Output: /data/trailmap_winter_finland.img"
echo "=========================================="
