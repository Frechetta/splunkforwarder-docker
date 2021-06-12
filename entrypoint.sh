#!/bin/bash

teardown() {
    "${SPLUNK_HOME}/bin/splunk" stop 2>/dev/null || true
}

trap teardown SIGINT SIGTERM

start() {
    # get labels and echo them
    metadata_file="/metadata"
    if [ -f "$metadata_file" ]; then
        awk -F'=' '{print "label :", $1, ":", $2}' "$metadata_file"
    fi

    # copy in default splunk etc files that come with distribution (important for upgrading)
    if [ -f "${SPLUNK_ETC_BACKUP_DIR}/splunk.version" ]; then
        image_version_sha=$(cat "${SPLUNK_ETC_BACKUP_DIR}/splunk.version" | sha512sum)

        if [ -f "${SPLUNK_HOME}/etc/splunk.version" ]; then
            etc_version_sha=$(cat "${SPLUNK_HOME}/etc/splunk.version" | sha512sum)
        fi

        # if versions are different, copy in etc backup dir files to SPLUNK_HOME/etc
        if [ "x$image_version_sha" != "x$etc_version_sha" ]; then
            echo "Updating ${SPLUNK_HOME}/etc"
            (cd "${SPLUNK_ETC_BACKUP_DIR}"; tar cf - *) | (cd "${SPLUNK_HOME}/etc"; tar xf -)
        fi
    fi

    # copy in custom etc files
    new_splunk_etc_dir=/splunk-etc
    if [ -d "$new_splunk_etc_dir" ]; then
        echo "Found Splunk etc"
        for f in $new_splunk_etc_dir/{,.[^.]}*; do  # match hidden and non-hidden files
            cp -r "$f" /opt/splunk/etc
        done
    fi

    # copy in apps
    if [ -d "/apps" ]; then
        for d in /apps/*; do
            name=${d##*/}
            echo "Found app \"$name\""
            rm -rf "${SPLUNK_HOME}/etc/apps/$name"
            cp -r "$d" "${SPLUNK_HOME}/etc/apps"
        done
    fi

    # execute "before" scripts
    before_scripts_dir=/before.d
    if [ -d "$before_scripts_dir" ]; then
        for f in $before_scripts_dir/*; do
            echo "Executing before script $f"
            $f
        done
    fi

    trap teardown EXIT

    if [ -z "${SPLUNK_PASSWORD}" ]; then
        echo "WARNING: No SPLUNK_PASSWORD env var. Splunk may fail to start."
        seed_arg=""
    else
        seed_arg="--seed-passwd ${SPLUNK_PASSWORD}"
    fi

    "${SPLUNK_HOME}/bin/splunk" start --accept-license --answer-yes --no-prompt $seed_arg

    # execute "after" scripts
    after_scripts_dir=/after.d
    if [ -d "$after_scripts_dir" ]; then
        for f in $after_scripts_dir/*; do
            echo "Executing after script $f"
            $f
        done
    fi

    tail -f "${SPLUNK_HOME}/var/log/splunk/splunkd_stderr.log" &
    wait
}

case "$1" in
    start)
        shift
        start
        ;;
    bash)
        /bin/bash
        ;;
esac
