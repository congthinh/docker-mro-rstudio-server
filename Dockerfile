FROM ubuntu:14.04
MAINTAINER Thinh Huynh <thinhhc@gmail.com>

## Add RStudio binaries to PATH 
ENV PATH /usr/lib/rstudio-server/bin/:$PATH 

## Add key-server and Ubuntu trusty (14.04) to sources.list
RUN DEBIAN_FRONTEND=noninteractive apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9
RUN echo "deb http://archive.ubuntu.com/ubuntu/ trusty multiverse" >> /etc/apt/sources.list

RUN apt-get update && \
apt-get upgrade -y

## Install some prerequisites libraries and dependencies for MRO
RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
    	ca-certificates \
	curl \
	nano \
	# MRO dependencies
	libcairo2 \
	libgfortran3 \
	libglib2.0-0 \
	libgomp1 \
	libjpeg8 \
	libpango-1.0-0 \
	libpangocairo-1.0-0 \
	libtcl8.6 \
	libtcl8.6 \
	libtiff5 \
	libtk8.6 \
	libx11-6 \
	libxt6 \
	# RevoMath dependencies
	build-essential \
	make \
	gcc \
	wget \
	g++ \
	file \ 
	git \ 
	libapparmor1 \ 
	libedit2 \ 
	libcurl4-openssl-dev \ 
	#libmariadb-client-lgpl-dev \
	libssl1.0.0 \ 
	libssl-dev \ 
	psmisc \ 
	python-setuptools \ 
	sudo \
	&& rm -rf /var/lib/apt/lists/*

## Latest MRO version https://mran.revolutionanalytics.com/documents/rro/installation/#revorinst-lin (3.2.4 as of May 19, 2016)
ENV MRO_VERSION 3.2.4

## Download & Install MRO
RUN curl -LO -# https://mran.revolutionanalytics.com/install/mro/$MRO_VERSION/MRO-$MRO_VERSION-Ubuntu-14.4.x86_64.deb
RUN dpkg -i MRO-$MRO_VERSION-Ubuntu-14.4.x86_64.deb
RUN rm MRO-*.deb

## Download and install RevoMath (formerly MKL) as user docker so that .Rprofile etc. are properly set
RUN curl -LO -# https://mran.revolutionanalytics.com/install/mro/$MRO_VERSION/RevoMath-$MRO_VERSION.tar.gz \
&& tar -xzf RevoMath-$MRO_VERSION.tar.gz

## Start noneinteractive installation
WORKDIR /home/docker/RevoMath
COPY ./RevoMath_install.sh RevoMath_install.sh
RUN ./RevoMath_install.sh \
	|| (echo "\n*** RevoMath Installation log ***\n" \
	&& cat mkl_log.txt \
	&& echo "")

RUN rm RevoMath-*.tar.gz
RUN rm -r RevoMath

## Download and Install Rstudio-server

RUN apt-get update
RUN wget -q http://download2.rstudio.org/rstudio-server-0.99.902-amd64.deb
RUN dpkg -i rstudio-server-0.99.902-amd64.deb
#RUN rm rstudio-server-*-amd64.deb \

## Configure default locale 
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
&& locale-gen en_US.utf8 \
&& /usr/sbin/update-locale LANG=en_US.UTF-8
ENV LC_ALL en_US.UTF-8 

RUN useradd -m -d /home/rstudio rstudio \
&& echo rstudio:rstudio | chpasswd

COPY userconf.sh /etc/cont-init.d/conf 
COPY run.sh /etc/services.d/rstudio/run 
COPY add-users.sh /usr/local/bin/add-users 

## Use s6 
RUN wget -P /tmp/ https://github.com/just-containers/s6-overlay/releases/download/v1.11.0.1/s6-overlay-amd64.tar.gz \
&& tar xzf /tmp/s6-overlay-amd64.tar.gz -C /

EXPOSE 8787 

## Expose a default volume for Kitematic 
VOLUME /home/docker 
CMD ["/init"]
