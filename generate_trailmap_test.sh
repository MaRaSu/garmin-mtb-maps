#!/bin/bash

# Multi-layer Trailmap generation - TEST VERSION
# This version includes verbose logging and does not clean up intermediate files
# Useful for debugging and development

set -e

# Expects /data/data.osm.pbf to exist
if [ ! -f /data/data.osm.pbf ]; then
	echo "ERROR: No import file at /data/data.osm.pbf"
	exit 1
fi

cd /home/renderer

echo "=========================================="
echo "Starting Trailmap Multi-Layer Generation (TEST MODE)"
echo "=========================================="
echo "Input file: /data/data.osm.pbf"
echo "Working directory: $(pwd)"
echo ""

# Extract Tampere region to reduce memory requirements
echo "=== Extracting Tampere Region ==="
echo "Bounding box: left=22.80 bottom=61.00 right=25.00 top=62.20"
osmosis --read-pbf file=/data/data.osm.pbf \
	--bounding-box left=22.80 bottom=61.00 right=25.00 top=62.20 \
	--write-pbf region_tampere.osm.pbf

REGION_FILE="region_tampere.osm.pbf"
echo "Region extracted: $(ls -lh $REGION_FILE)"
echo ""

# LAYER 1: Routing layer (draw-priority=1, mapid starts at 80010000)
echo ""
echo "=== Processing Routing Layer ==="
echo "Splitting OSM data for routing layer..."
java -Xmx4000m -jar splitter.jar $REGION_FILE \
	--output=pbf \
	--output-dir=split_routing \
	--description="Test Routing" \
	--precomp-sea=sea.zip \
	--geonames-file=cities.zip \
	--max-areas=4096 \
	--max-nodes=1000000 \
	--mapid=80010000 \
	--status-freq=2 \
	--keep-complete=true

echo "Renaming template.args for routing layer..."
mv split_routing/template.args split_routing/trailmap_routing_v1-test.args
echo "Split files created: $(ls -lh split_routing/*.pbf | wc -l) PBF files"

echo "Compiling routing layer..."
java -Xmx6000m -jar mkgmap.jar \
	--location-autofill=is_in \
	--draw-priority=1 \
	--code-page=1252 \
	--latin1 \
	--family-id=8800 \
	--product-id=1 \
	--mapname=80000001 \
	--style-file=trailmap_routing_v1/ \
	--bounds=bounds.zip \
	--net \
	--route \
	--ignore-turn-restrictions \
	--index \
	--output-dir=compiled_routing \
	-c split_routing/trailmap_routing_v1-test.args

echo "Routing layer compiled: $(ls -lh compiled_routing/*.img | wc -l) IMG files"

# LAYER 2: Bottom layer (draw-priority=90, mapid starts at 80020000)
echo ""
echo "=== Processing Bottom Layer ==="
echo "Splitting OSM data for bottom layer..."
java -Xmx4000m -jar splitter.jar $REGION_FILE \
	--output=pbf \
	--output-dir=split_bottom \
	--description="Test Bottom" \
	--precomp-sea=sea.zip \
	--geonames-file=cities.zip \
	--max-areas=4096 \
	--max-nodes=1000000 \
	--mapid=80020000 \
	--status-freq=2 \
	--keep-complete=true

echo "Renaming template.args for bottom layer..."
mv split_bottom/template.args split_bottom/trailmap_bottom_v1-test.args
echo "Split files created: $(ls -lh split_bottom/*.pbf | wc -l) PBF files"

echo "Compiling bottom layer..."
java -Xmx6000m -jar mkgmap.jar \
	--draw-priority=90 \
	--code-page=1252 \
	--min-size-polygon=12 \
	--latin1 \
	--family-id=8800 \
	--product-id=1 \
	--mapname=80000002 \
	--style-file=trailmap_bottom_v1/ \
	--precomp-sea=sea.zip \
	--generate-sea \
	--bounds=bounds.zip \
	--output-dir=compiled_bottom \
	-c split_bottom/trailmap_bottom_v1-test.args

echo "Bottom layer compiled: $(ls -lh compiled_bottom/*.img | wc -l) IMG files"

# LAYER 3: Main layer (draw-priority=91, transparent, mapid starts at 80030000)
echo ""
echo "=== Processing Main Layer ==="
echo "Splitting OSM data for main layer..."
java -Xmx4000m -jar splitter.jar $REGION_FILE \
	--output=pbf \
	--output-dir=split_main \
	--description="Test Main" \
	--precomp-sea=sea.zip \
	--geonames-file=cities.zip \
	--max-areas=4096 \
	--max-nodes=1000000 \
	--mapid=80030000 \
	--status-freq=2 \
	--keep-complete=true

echo "Renaming template.args for main layer..."
mv split_main/template.args split_main/trailmap_main_v1-test.args
echo "Split files created: $(ls -lh split_main/*.pbf | wc -l) PBF files"

echo "Compiling main layer..."
java -Xmx6000m -jar mkgmap.jar \
	--draw-priority=91 \
	--transparent \
	--code-page=1252 \
	--latin1 \
	--family-id=8800 \
	--product-id=1 \
	--mapname=80000003 \
	--style-file=trailmap_main_v1/ \
	--bounds=bounds.zip \
	--output-dir=compiled_main \
	-c split_main/trailmap_main_v1-test.args

echo "Main layer compiled: $(ls -lh compiled_main/*.img | wc -l) IMG files"

# Delete osmmap overview files from each compiled directory (they have duplicate IDs)
echo ""
echo "=== Removing osmmap overview files ==="
rm -f compiled_routing/osmmap.img compiled_routing/osmmap.mdx compiled_routing/osmmap.tdb compiled_routing/osmmap_mdr.img
rm -f compiled_bottom/osmmap.img compiled_bottom/osmmap.mdx compiled_bottom/osmmap.tdb compiled_bottom/osmmap_mdr.img
rm -f compiled_main/osmmap.img compiled_main/osmmap.mdx compiled_main/osmmap.tdb compiled_main/osmmap_mdr.img
echo "osmmap files removed from all compiled directories"

# MERGE: Use gmap CLI tool to merge all layers
echo ""
echo "=== Merging Layers ==="
echo "Merging all three layers into single map file..."
echo "Command: gmt -j -f 8800,1 -m \"Trailmap MTB Test\" -o /data/trailmap_test.img"

/home/renderer/bin/gmt \
	-j \
	-f 8800,1 \
	-m "Trailmap MTB Test" \
	-o /data/trailmap_test.img \
	compiled_routing/*.img \
	compiled_bottom/*.img \
	compiled_main/*.img \
	trailmap_mtb_v1.typ

# Remove intermediate osmmap files if they exist
rm -f /data/osmmap.img /data/osmmap.mdx /data/osmmap.tdb /data/osmmap_mdr.img

echo ""
echo "=== Test Mode: Keeping intermediate files ==="
echo "Region file preserved for inspection:"
echo "  - region_tampere.osm.pbf"
echo "Split directories preserved for inspection:"
echo "  - split_routing/"
echo "  - split_bottom/"
echo "  - split_main/"
echo "Compiled directories preserved for inspection:"
echo "  - compiled_routing/"
echo "  - compiled_bottom/"
echo "  - compiled_main/"

echo ""
echo "=========================================="
echo "Trailmap generation completed successfully!"
echo "Output: /data/trailmap_test.img"
echo "Intermediate files kept for debugging"
echo "=========================================="
