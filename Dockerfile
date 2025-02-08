FROM ubuntu:24.04

# Set up environment and renderer user
ENV TZ=Europe/Helsinki
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN useradd -m -s /bin/bash renderer
RUN mkdir /osm-data
RUN chown renderer /osm-data

# Install packages
RUN apt-get --yes update && \
	apt-get install --yes --no-install-recommends apt-utils apt-transport-https ca-certificates gpg openjdk-8-jdk python3 osmosis wget git-core \
	unzip pigz tar \
	&& apt-get clean autoclean \
	&& apt-get autoremove --yes \
	&& rm -rf /var/lib/{apt,dpkg,cache,log}/

# Install Minio client
RUN wget https://dl.min.io/client/mc/release/linux-amd64/mc && \
    chmod +x mc && mv mc /usr/local/bin/mc

# Init user renderer
USER renderer
RUN mkdir /home/renderer/download
RUN mkdir /home/renderer/styles

# Install SPLITTER
WORKDIR /home/renderer/download
RUN wget -nv http://www.mkgmap.org.uk/download/splitter-r654.zip
RUN unzip splitter*.zip
RUN mv splitter*.zip splitter*/
RUN mv splitter* splitter
RUN mv splitter/splitter.jar ../
RUN mv splitter/lib ../

# Install MKGMAPS
WORKDIR /home/renderer/download
RUN wget -nv http://www.mkgmap.org.uk/download/mkgmap-r4923.zip
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
RUN mv TK_pathsonly ../
COPY *.typ /home/renderer/

# Copy scripts
COPY --chown=renderer *.sh /home/renderer/
COPY --chown=renderer *.py /home/renderer/

WORKDIR /home/renderer
ENTRYPOINT ["/home/renderer/run.sh"]
CMD []
