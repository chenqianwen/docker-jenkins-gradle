FROM jenkins/jenkins:lts

ENV SDKMAN_DIR /usr/share/sdkman/dir

USER root
ADD jenkins-gradle.sh /usr/local/bin/
ENTRYPOINT ["/sbin/tini", "--", "jenkins-gradle.sh"]
RUN apt-get update && apt-get install -y zip && rm -rf /var/lib/apt/lists/* \
    && mkdir -p "$(dirname "$SDKMAN_DIR")" \
    && chown -R jenkins: "$(dirname "$SDKMAN_DIR")"

USER jenkins
SHELL ["/bin/bash", "-c"]
RUN curl -s "https://get.sdkman.io" | bash \
    && source "$SDKMAN_DIR/bin/sdkman-init.sh" \
    && sdk install gradle 4.8\
    && sdk install maven\
    && /usr/local/bin/install-plugins.sh git gradle workflow-aggregator pipeline-utility-steps active-directory maven

USER root
RUN curl -O https://get.docker.com/builds/Linux/x86_64/docker-latest.tgz \
    && tar zxvf docker-latest.tgz \
    && cp docker/docker /usr/local/bin/ \
    && rm -rf docker docker-latest.tgz
RUN echo "jenkins ALL=NOPASSWD: ALL" >> /etc/sudoers
#
# nodejs
#
RUN mkdir /nodejs
RUN curl -O http://nodejs.org/dist/v10.15.3/node-v10.15.3-linux-x64.tar.gz
RUN tar xvzf node-v10.15.3-linux-x64.tar.gz -C /nodejs --strip-components=1
ENV PATH $PATH:/nodejs/bin
RUN npm install -g cnpm --registry=https://registry.npm.taobao.org#
# maven
#
# Install maven
USER root
RUN apt-get update && apt-get install -y wget
# get maven 3.5.3
RUN wget --no-verbose -O /tmp/apache-maven-3.6.0.tar.gz http://archive.apache.org/dist/maven/maven-3/3.6.0/binaries/apache-maven-3.6.0-bin.tar.gz
# install maven
RUN tar xzf /tmp/apache-maven-3.6.0.tar.gz -C /opt/
RUN ln -s /opt/apache-maven-3.6.0 /opt/maven
RUN ln -s /opt/maven/bin/mvn /usr/local/bin
RUN rm -f /tmp/apache-maven-3.6.0.tar.gz
ENV MAVEN_HOME /opt/maven
# Switch back to Jenkins user
USER jenkins
