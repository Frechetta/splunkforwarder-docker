ARG SPLUNK_HOME_DEFAULT=/opt/splunkforwarder
ARG SPLUNK_ETC_BACKUP_DIR_DEFAULT=/opt/splunkforwarder-etc

FROM debian:bullseye-slim as base

ARG SPLUNK_HOME_DEFAULT
ENV SPLUNK_HOME ${SPLUNK_HOME_DEFAULT}

ARG SPLUNK_ETC_BACKUP_DIR_DEFAULT
ENV SPLUNK_ETC_BACKUP_DIR ${SPLUNK_ETC_BACKUP_DIR_DEFAULT}

ARG version
ARG version_number
ENV SPLUNK_VER $version_number
ENV SPLUNK_VER_FULL $version
ENV SPLUNK_FILENAME splunkforwarder-${SPLUNK_VER_FULL}-Linux-x86_64.tgz

# OPTIMISTIC_ABOUT_FILE_LOCKING from https://docs.splunk.com/Documentation/Splunk/8.0.3/Troubleshooting/FSLockingIssues
RUN apt update -y && \
    apt install -y wget && \
    wget -O /tmp/${SPLUNK_FILENAME} "https://www.splunk.com/bin/splunk/DownloadActivityServlet?architecture=x86_64&platform=linux&version=${SPLUNK_VER}&product=universalforwarder&filename=${SPLUNK_FILENAME}&wget=true" && \
    mkdir ${SPLUNK_HOME} && \
    tar -xzf /tmp/${SPLUNK_FILENAME} --strip 1 -C ${SPLUNK_HOME} && \
    # echo "OPTIMISTIC_ABOUT_FILE_LOCKING = 1" > ${SPLUNK_HOME}/etc/splunk-launch.conf && \
    mv ${SPLUNK_HOME}/etc ${SPLUNK_ETC_BACKUP_DIR} && \
    mkdir ${SPLUNK_HOME}/etc ${SPLUNK_HOME}/var && \
    chown 999:999 -R ${SPLUNK_HOME} ${SPLUNK_ETC_BACKUP_DIR}

FROM debian:bullseye-slim

ARG SPLUNK_HOME_DEFAULT
ENV SPLUNK_HOME ${SPLUNK_HOME_DEFAULT}

ARG SPLUNK_ETC_BACKUP_DIR_DEFAULT
ENV SPLUNK_ETC_BACKUP_DIR ${SPLUNK_ETC_BACKUP_DIR_DEFAULT}

COPY --from=base ${SPLUNK_HOME} ${SPLUNK_HOME}
COPY --from=base ${SPLUNK_ETC_BACKUP_DIR} ${SPLUNK_ETC_BACKUP_DIR}

WORKDIR ${SPLUNK_HOME}

COPY entrypoint.sh /sbin/entrypoint.sh
RUN apt update && \
    apt upgrade -y && \
    apt install -y procps tini && \
    addgroup --system --gid 999 splunk && \
    adduser --system --uid 999 --home ${SPLUNK_HOME} --no-create-home --group splunk && \
    chown splunk:splunk ${SPLUNK_HOME} ${SPLUNK_ETC_BACKUP_DIR} && \
    chmod 755 /sbin/entrypoint.sh

USER splunk

ENTRYPOINT ["tini", "--", "/sbin/entrypoint.sh"]
CMD ["start"]
