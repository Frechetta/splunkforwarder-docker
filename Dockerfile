ARG SPLUNK_HOME_DEFAULT=/opt/splunkforwarder
ARG SPLUNK_ETC_BACKUP_DIR_DEFAULT=/opt/splunkforwarder-etc

FROM debian:bullseye-slim as base

ARG SPLUNK_HOME_DEFAULT
ENV SPLUNK_HOME ${SPLUNK_HOME_DEFAULT}

ARG SPLUNK_ETC_BACKUP_DIR_DEFAULT
ENV SPLUNK_ETC_BACKUP_DIR ${SPLUNK_ETC_BACKUP_DIR_DEFAULT}

# Getting Version Info
# 1. Go to https://www.splunk.com/en_us/download/universal-forwarder.html
# 2. Log in
# 3. Click on the "Linux" tab
# 4. Click on the "Download Now" button for the ".tgz" distribution
# 5. Splunk will start downloading; cancel it
# 6. Click on the `Command Line (wget)` link in the "Useful Tools" box in the upper right of the page
# 7. Copy the string of characters after "wget -O splunkforwarder-" and before "-Linux-x86_64.tgz..." (e.g. `8.0.6-152fb4b2bb96`)
# 8. Replace the contents of the `splunk-ver` file with the string you just copied
ENV SPLUNK_VER 8.2.0
ENV SPLUNK_VER_FULL ${SPLUNK_VER}-e053ef3c985f
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
