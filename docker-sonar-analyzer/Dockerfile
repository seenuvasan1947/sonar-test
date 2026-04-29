FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV SONARQUBE_VERSION=10.4.1.88267
ENV SONARSCANNER_VERSION=5.0.1.3006
ENV SONARQUBE_HOME=/opt/sonarqube
ENV SONAR_SCANNER_HOME=/opt/sonar-scanner
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH="${SONAR_SCANNER_HOME}/bin:${JAVA_HOME}/bin:${PATH}"

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    jq \
    wget \
    unzip \
    openjdk-17-jdk \
    openssl \
    procps \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create sonar user (SonarQube refuses to run as root)
RUN groupadd -g 1000 sonar && \
    useradd -u 1000 -g sonar -m -d /opt/sonarqube-home sonar

# Install SonarQube
RUN wget -q \
    "https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-${SONARQUBE_VERSION}.zip" \
    -O /tmp/sonarqube.zip && \
    unzip -q /tmp/sonarqube.zip -d /opt && \
    mv /opt/sonarqube-${SONARQUBE_VERSION} ${SONARQUBE_HOME} && \
    rm /tmp/sonarqube.zip

# Install SonarScanner CLI
RUN wget -q \
    "https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SONARSCANNER_VERSION}-linux.zip" \
    -O /tmp/scanner.zip && \
    unzip -q /tmp/scanner.zip -d /opt && \
    mv /opt/sonar-scanner-${SONARSCANNER_VERSION}-linux ${SONAR_SCANNER_HOME} && \
    rm /tmp/scanner.zip

# Tune SonarQube memory for single-container use
RUN echo "sonar.web.javaOpts=-Xmx512m -Xms128m" >> ${SONARQUBE_HOME}/conf/sonar.properties && \
    echo "sonar.search.javaOpts=-Xmx512m -Xms256m" >> ${SONARQUBE_HOME}/conf/sonar.properties && \
    echo "sonar.ce.javaOpts=-Xmx256m -Xms64m" >> ${SONARQUBE_HOME}/conf/sonar.properties

# Create required directories and set ownership
RUN mkdir -p /output /code && \
    chown -R sonar:sonar ${SONARQUBE_HOME} ${SONAR_SCANNER_HOME} /output /code

WORKDIR /app

COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh && chown sonar:sonar /app/entrypoint.sh

# Switch to non-root (required by SonarQube)
USER sonar

VOLUME ["/code", "/output"]

ENTRYPOINT ["/app/entrypoint.sh"]
