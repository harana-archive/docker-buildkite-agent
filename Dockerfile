FROM phusion/baseimage:latest

RUN apt-get update && apt-get install -y \
    bash \
    git \
    openjdk-8-jdk \
    curl \
    docker.io \
    nodejs \
    npm \
    tzdata \
    ca-certificates \
    groff \
    less \
    python3-pip

RUN pip3 install --upgrade awscli

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV BUILDKITE_BUILD_PATH=/buildkite/builds \
    BUILDKITE_HOOKS_PATH=/buildkite/hooks \
    BUILDKITE_PLUGINS_PATH=/buildkite/plugins

RUN mkdir -p ${BUILDKITE_BUILD_PATH} ${BUILDKITE_HOOKS_PATH} ${BUILDKITE_PLUGINS_PATH} \
    && curl -Lfs -o /usr/local/bin/ssh-env-config.sh https://raw.githubusercontent.com/buildkite/docker-ssh-env-config/master/ssh-env-config.sh \
    && chmod +x /usr/local/bin/ssh-env-config.sh

RUN curl -sL https://github.com/buildkite/agent/releases/download/v3.0.1/buildkite-agent-linux-amd64-3.0.1.tar.gz | gunzip | tar -x -C /buildkite && \
    mv /buildkite/buildkite-agent /usr/local/bin && \
    chmod +x /usr/local/bin/buildkite-agent

COPY ./entrypoint.sh /usr/local/bin/buildkite-agent-entrypoint

COPY ./environment $BUILDKITE_HOOKS_PATH

# Install Tini
ENV TINI_VERSION v0.18.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /sbin/tini
RUN chmod +x /sbin/tini

# Install SBT
ENV SBT_VERSION=1.1.4
ENV SBT_HOME=/usr/local/sbt
ENV PATH=${PATH}:${SBT_HOME}/bin

RUN curl -sL "https://github.com/sbt/sbt/releases/download/v$SBT_VERSION/sbt-$SBT_VERSION.tgz" | gunzip | tar -x -C /usr/local && \
    echo -ne "- with sbt $SBT_VERSION\n" >> /root/.built && \
    chmod 0755 $SBT_HOME/bin/sbt

# Install Maven
ENV MVN_VERSION=3.5.3
ENV MVN_HOME=/usr/local/apache-maven-${MVN_VERSION}
ENV PATH=${PATH}:${MVN_HOME}/bin

RUN curl -sL "https://archive.apache.org/dist/maven/maven-3/${MVN_VERSION}/binaries/apache-maven-${MVN_VERSION}-bin.tar.gz" | gunzip | tar -x -C /usr/local && \
    echo -ne "- with mvn $MVN_VERSION\n" >> /root/.built && \
    chmod 0755 $MVN_HOME/bin/mvn

VOLUME /buildkite
ENTRYPOINT ["buildkite-agent-entrypoint"]
CMD ["start"]
