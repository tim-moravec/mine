######Appium,Ruby/RVM,Cucumber############
FROM ubuntu:16.10
MAINTAINER Tim Moravec <tim.moravec@wheniwork.com>

RUN apt-get update
RUN apt-get -y install curl build-essential

RUN apt-get install -y nginx openssh-server git-core openssh-client curl
RUN apt-get install -y nano
RUN apt-get install -y build-essential
RUN apt-get install -y openssl libreadline6 libreadline6-dev curl zlib1g zlib1g-dev libssl-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt-dev autoconf libc6-dev ncurses-dev automake libtool bison subversion pkg-config

# install RVM, Ruby, and Bundler
RUN gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
RUN \curl -L https://get.rvm.io | bash -s stable
RUN /bin/bash -l -c "rvm requirements"
RUN /bin/bash -l -c "rvm install 2.4"
RUN /bin/bash -l -c "gem install bundler --no-ri --no-rdoc"
RUN /bin/bash -l -c "gem install bddfire -v 1.9.7 --no-ri --no-rdoc"
RUN /bin/bash -l -c "gem install cucumber --no-ri --no-rdoc"
RUN /bin/bash -l -c "gem install capybara --no-ri --no-rdoc"
RUN /bin/bash -l -c "gem install poltergeist --no-ri --no-rdoc"
RUN /bin/bash -l -c "gem install rspec --no-ri --no-rdoc"
RUN /bin/bash -l -c "gem install appium_lib --no-ri --no-rdoc"
RUN /bin/bash -l -c "bddfire fire_cucumber"
RUN /bin/bash -l -c "cd cucumber&&bundle install"

#Install maven
RUN apt-get install -y maven

USER jenkins
WORKDIR /home/jenkins

RUN  mkdir .local && mkdir node
RUN curl http://nodejs.org/dist/node-latest.tar.gz | tar xz --strip-components=1
RUN ./configure --prefix=.local && make install

ENV NODE_PATH=/home/jenkins/.local/lib/node_modules
ENV PATH=/home/jenkins/.local/bin:$PATH


USER root
# Expose bin to default nodejs bin for sublime plugins
RUN ln -s /home/jenkins/.local/bin/node  /usr/bin/nodejs
RUN ln -s /home/jenkins/.local/lib/node_modules /usr/local/lib/

ENV appium_args "-p 8080"

USER jenkins
#Install npm
RUN curl -O https://npmjs.com/install.sh | sh

ENV appium_version 1.5.3
#Install appium
RUN npm install -g appium@${appium_version}

ENV phantomjs_version 1.9.7
#Install PhantomJS
RUN npm install -g phantomjs

ADD files/insecure_shared_adbkey /home/jenkins/.android/adbkey
ADD files/insecure_shared_adbkey.pub /home/jenkins/.android/adbkey.pub

USER root
RUN apt-get -y install supervisor
RUN mkdir -p /var/log/supervisor
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
RUN adb kill-server
RUN adb start-server
RUN adb devices
EXPOSE 22
CMD ["/usr/bin/supervisord"]



###############GENYMOTION##################
# Specify the binary we want to use
ENV GENY_VERSION=2.8.1

RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        linux-headers-4.4.0-22-generic \
        openssl \
        wget \
    \
    # Install Virtual Box 5.0
    && wget -q --directory-prefix=/tmp/ "http://files2.genymotion.com/genymotion/genymotion-${GENY_VERSION}/genymotion-${GENY_VERSION}-linux_x64.bin" \
    && echo "deb http://download.virtualbox.org/virtualbox/debian xenial contrib" >> /etc/apt/sources.list \
    && wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | apt-key add - \
    && wget -q https://www.virtualbox.org/download/oracle_vbox.asc -O- | apt-key add - \
    && apt-get update && apt-get install -y \
        virtualbox-5.0 \
    \
    # Install Genymotion
    && mkdir -p /genymotion/ \
    && apt-get install -y --no-install-recommends \
        bzip2 \
        libgstreamer-plugins-base0.10-dev \
        libxcomposite-dev \
        libxslt1.1 \
    && chmod +x /tmp/genymotion-${GENY_VERSION}-linux_x64.bin \
    && mkdir -p /root/.Genymobile/ \
    # Weird AUFs bug errors with 'file in use', fixed with sync command
    && sync \
    && echo 'Y' | /tmp/genymotion-${GENY_VERSION}-linux_x64.bin -d / \
    \
    # Cleanup
    && rm -f /tmp/genymotion-${GENY_VERSION}-linux_x64.bin \
    && apt-get autoremove -y --purge \
        wget \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

VOLUME ["/tmp/.X11-unix", "/root/"]
ENTRYPOINT ["/genymotion/genymotion"]