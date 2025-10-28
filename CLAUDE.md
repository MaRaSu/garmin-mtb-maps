# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Garmin MTB map generation system that converts OpenStreetMap data into Garmin-compatible map files (.img format) for mountain biking in Finland. The system runs in Docker and generates maps for various Finnish regions using mkgmap and splitter tools.

## Architecture

### Map Generation Pipeline

The map generation process follows this flow:

1. **Data Acquisition**: OSM data (.osm.pbf files) is downloaded from MinIO object storage or Geofabrik
2. **Region Extraction**: Osmosis extracts specific regions using bounding box coordinates
3. **Splitting**: Splitter divides large regions into manageable tiles
4. **Map Compilation**: mkgmap converts OSM data to Garmin format using custom TK style files
5. **Output Storage**: Generated .img files are packaged and uploaded back to MinIO

### Key Components

- **generate_maps.sh**: Main map generation script that creates all regional maps for Finland. Calls `create_map()` function for each region with parameters: bounding box coordinates, style directory, output filename, map ID, and optional transparency flags.

- **create_map() function**: The core map generation workflow (in generate_maps*.sh files) that:
  - Extracts region with Osmosis using bounding box
  - Splits with splitter.jar (max 4096 areas, 1M nodes per area)
  - Fixes template.args descriptions via fix_names.py
  - Compiles with mkgmap.jar using family-id=8888, product-id=1
  - Produces both standard maps (TK style) and transparent overlay maps (TK_pathsonly style)

- **Map IDs and Naming**: Each map requires unique mapid (e.g., 88880001) and mapname. Family ID is consistently 8888. Path overlay maps use --transparent and --draw-priority=30 flags.

- **Style Files**: Two .typ files are used:
  - tk_finland_v2_noborders.typ
  - tk_finland_v2_bitmapborders.typ
  - Styles are cloned from https://github.com/Myrtillus/Garmin_OSM_TK_map.git during Docker build

### Docker Workflow

The application is designed to run entirely in Docker:
- Base image: Ubuntu 24.04
- Java 8 JDK for mkgmap/splitter
- Osmosis for OSM data processing
- MinIO client (mc) for object storage
- Volume mount for testing: `/data` (maps to local osm-data/ directory for both input and output)

### Storage Integration

MinIO object storage is used for data persistence:
- **get_from_store.sh**: Downloads OSM data files named with weekday suffix (e.g., finland_1.osm.pbf)
- **upload_to_store.sh**: Uploads generated maps as tar.gz archives with weekday rotation
- **config_minio.sh**: Configures mc client with S3_ACCESS_KEY and S3_SECRET_KEY environment variables
- Retry logic with 5 attempts and 60-second backoff for network resilience

## Common Commands

### Build and Test

```bash
# Build Docker image (production - linux/amd64)
make build

# Build for local development (native architecture - faster on M-series Macs)
make build_local

# Build and run interactively with volume mounts
make test

# Build and run with bash shell access (uses amd64 via emulation)
make test_sh

# Build and run with bash shell access (native architecture - recommended for M-series Macs)
make test_sh_local
```

**Note for Mac M-series users**: Use `make test_sh_local` for much faster testing. The regular `make test_sh` builds for linux/amd64 which runs slower through emulation on Apple Silicon.

### Running Map Generation

Inside the container:

**TK Maps (Traditional single-layer maps):**
```bash
# Generate all regional maps (full production)
./generate_maps.sh

# Generate only Finland-wide map
./generate_maps_fin.sh

# Generate test maps for Tampere region with different styles
./generate_maps_test.sh
```

**Trailmap (Multi-layer maps for modern Garmin devices):**
```bash
# Generate multi-layer Finland map
./generate_trailmap.sh

# Generate with verbose output and keep intermediate files
./generate_trailmap_test.sh
```

### Full Automated Pipeline

The entrypoint script `run.sh` automates the complete workflow:

1. **Configure MinIO client** - Set up object storage access
2. **Download OSM data** - Fetch `finland_${WEEKDAY}.osm.pbf` from MinIO
3. **Generate TK maps** - Create all regional TK maps via `generate_maps.sh`
4. **Upload TK maps** - Package and upload to MinIO as `garmin-finland_${WEEKDAY}.tar.gz`
5. **Cleanup** - Remove TK map outputs from `/data/`
6. **Generate trailmap** - Create multi-layer Finland map via `generate_trailmap.sh`
7. **Upload trailmap** - Package and upload to MinIO as `garmin_new-finland_${WEEKDAY}.tar.gz`

Both map types use the same source OSM data but are generated and uploaded separately to avoid conflicts.

### Version Management

Update VERSION in Makefile for new releases. Image is tagged as `$(REGISTRY)/$(IMAGE_NAME):$(VERSION)`.

## Multi-Layer Trailmap Architecture

The trailmap system generates maps compatible with modern Garmin devices by creating three separate layers that are merged into a single map file:

### Three-Layer Structure

1. **Routing Layer** (draw-priority=1, mapid 80010000+)
   - Provides routing and navigation functionality
   - Compiled with --net, --route, --ignore-turn-restrictions, --index flags
   - Uses trailmap_routing_v1 style

2. **Bottom Layer** (draw-priority=90, mapid 80020000+)
   - Background terrain and base map features
   - Includes sea generation (--precomp-sea, --generate-sea)
   - Uses trailmap_bottom_v1 style
   - Optional: --min-size-polygon=12

3. **Main Layer** (draw-priority=91, mapid 80030000+)
   - Transparent overlay with trail details and POIs
   - Compiled with --transparent flag
   - Uses trailmap_main_v1 style

### Processing Workflow

```
/data/data.osm.pbf (complete Finland dataset)
    │
    ├─> Split with splitter.jar (mapid=80010000)
    │   └─> Compile routing layer → compiled_routing/*.img
    │
    ├─> Split with splitter.jar (mapid=80020000)
    │   └─> Compile bottom layer → compiled_bottom/*.img
    │
    └─> Split with splitter.jar (mapid=80030000)
        └─> Compile main layer → compiled_main/*.img

Merge with gmt CLI → /data/trailmap_finland.img
```

### Key Differences from TK Maps

- **TK Maps**: Single-layer, region-based with bounding box extraction
- **Trailmap**: Multi-layer, complete dataset only (no region extraction)
- **TK Maps**: Family ID 8888, simple create_map() function
- **Trailmap**: Family ID 8800, three-stage split-compile-merge workflow
- **TK Maps**: Uses mkgmap for final output
- **Trailmap**: Uses gmt CLI tool for merging (mkgmap cannot merge overlapping layers)

### Trailmap Configuration

- All layers share family-id=8800, product-id=1
- Currently splits data three times (optimization possible by copying/editing template.args)
- Styles from local directory: `trailmap-garmin/` (cloned from private repository)
- Required style directories: trailmap_routing_v1, trailmap_bottom_v1, trailmap_main_v1
- Output: `/data/trailmap_finland.img`
- MinIO upload prefix: `garmin_new-finland` (vs. `garmin-finland` for TK maps)
- Uses gmt binary located at /home/renderer/bin/gmt
- TYP file: trailmap_mtb_v1.typ (included in trailmap-garmin directory)

## Development Notes

### Map Configuration Parameters

When adding new regions, the create_map function takes these arguments:
1. left (longitude)
2. bottom (latitude)
3. right (longitude)
4. top (latitude)
5. style directory (TK or TK_pathsonly)
6. description for splitter
7. .typ file basename
8. description for mkgmap (max 20 chars)
9. unique map ID (8-digit number)
10. output filename
11. optional mkgmap flags (for transparent overlays)

### Java Memory Settings

- Splitter: -Xmx4000m (4GB heap)
- mkgmap: -Xmx6000m (6GB heap)

### File Locations in Container

- Tools: /home/renderer/splitter.jar, mkgmap.jar, bin/gmt
- Libraries: /home/renderer/lib/
- Data files: bounds.zip, sea.zip, cities.zip
- TK Styles: /home/renderer/TK/, /home/renderer/TK_pathsonly/
- Trailmap Styles: /home/renderer/trailmap_routing_v1/, trailmap_bottom_v1/, trailmap_main_v1/
- Working directory: /home/renderer/
- Data mount: /data/ (maps to local osm-data/ during testing) - used for both input OSM files and output .img files

### Weekday-Based Data Management

The storage system uses weekday numbers (1-7) for file versioning. Old versions are automatically cleaned up (WEEKDAY_MINUS_2).

### Prerequisites for Building

**For Trailmap Support:**

1. **gmt CLI Tool**: Required for trailmap multi-layer map merging. Place the Ubuntu CLI version of GMapTool (command name: `gmt`) at `bin/gmt` before building the Docker image. This binary is not included in the repository and must be obtained separately. The tool is necessary because mkgmap cannot properly merge overlapping map layers.

2. **trailmap-garmin Directory**: The trailmap styles must be cloned locally. Clone the private repository to `trailmap-garmin/` directory at the root of this repository before building:
   ```bash
   # Clone the private repo (requires access)
   git clone https://github.com/TapioKn/trailmap-garmin.git trailmap-garmin
   ```
   Required contents:
   - trailmap_routing_v1/
   - trailmap_bottom_v1/
   - trailmap_main_v1/
   - trailmap_mtb_v1.typ

The trailmap-garmin directory is in .gitignore and will not be committed to this repository.
