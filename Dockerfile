FROM ubuntu:18.04

# Set up environment and renderer user
ENV TZ=Europe/Helsinki
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN adduser --disabled-password --gecos "" renderer
RUN mkdir /osm-data
RUN chown renderer /osm-data

# Install packages
RUN apt-get --yes update && \
	apt-get install --yes apt-utils openjdk-8-jdk python3 osmosis wget git-core  \
	&& apt-get clean autoclean \
	&& apt-get autoremove --yes \
	&& rm -rf /var/lib/{apt,dpkg,cache,log}/

# Init user renderer
USER renderer
RUN mkdir /home/renderer/download
RUN mkdir /home/renderer/styles

# Install SPLITTER
WORKDIR /home/renderer/download
RUN wget -nv http://www.mkgmap.org.uk/download/splitter-r597.zip
RUN unzip splitter*.zip
RUN mv splitter*.zip splitter*/
RUN mv splitter* splitter
RUN mv splitter/splitter.jar ../
RUN mv splitter/lib ../

# Install MKGMAPS
WORKDIR /home/renderer/download
RUN wget -nv http://www.mkgmap.org.uk/download/mkgmap-r4483.zip
RUN unzip mkgmap*.zip
RUN mv mkgmap*.zip mkgmap*/
RUN mv mkgmap* mkgmap
RUN mv mkgmap/mkgmap.jar ../
RUN cp mkgmap/lib/* ../lib/

# Install OSM data files
RUN wget -nv http://osm.thkukuk.de/data/bounds-latest.zip -O bounds.zip
RUN wget -nv http://osm.thkukuk.de/data/sea-latest.zip -O sea.zip
RUN wget -nv http://download.geonames.org/export/dump/cities15000.zip -O cities.zip
RUN mv *.zip ../

# Configure stylesheets
ARG NOCACHE=0
WORKDIR /home/renderer/styles
RUN git clone https://github.com/Myrtillus/Garmin_OSM_TK_map.git .
RUN mv *.typ ../
RUN mv TK ../

# Copy scripts
COPY --chown=renderer *.sh /home/renderer/
COPY --chown=renderer *.py /home/renderer/

WORKDIR /home/renderer
CMD /home/renderer/generate_maps.sh