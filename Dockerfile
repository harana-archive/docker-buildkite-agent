FROM mhart/alpine-node:4

RUN apk add --no-cache \
    tini \
    bash \
    git \
    perl \
    rsync \
    openssh-client \
    curl \
    docker \
    jq \
    su-exec \
    py-pip \
    libc6-compat \
    run-parts \
    tzdata \
    ca-certificates \
    groff \
    less \
  && \
  pip install --upgrade pip && \
  pip install docker-compose

ENV BUILDKITE_BUILD_PATH=/buildkite/builds \
    BUILDKITE_HOOKS_PATH=/buildkite/hooks \
    BUILDKITE_PLUGINS_PATH=/buildkite/plugins

RUN pip install docker-compose

RUN mkdir -p /buildkite/builds /buildkite/hooks /buildkite/plugins \
    && curl -Lfs -o /usr/local/bin/ssh-env-config.sh https://raw.githubusercontent.com/buildkite/docker-ssh-env-config/master/ssh-env-config.sh \
    && chmod +x /usr/local/bin/ssh-env-config.sh

RUN curl -sL https://github.com/buildkite/agent/releases/download/v3.0.1/buildkite-agent-linux-amd64-3.0.1.tar.gz | gunzip | tar -x -C /buildkite && \
    mv /buildkite/buildkite-agent /usr/local/bin && \
    chmod +x /usr/local/bin/buildkite-agent

COPY ./entrypoint.sh /usr/local/bin/buildkite-agent-entrypoint

COPY ./environment $BUILDKITE_HOOKS_PATH

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

# Install AWS CLI
RUN pip --no-cache-dir install awscli

VOLUME /buildkite
ENTRYPOINT ["buildkite-agent-entrypoint"]
CMD ["start"]
