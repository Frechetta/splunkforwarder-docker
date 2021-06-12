#!/bin/bash

root_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
root_dir=${root_dir/\/cygdrive\/c\//C:\/}
root_dir=${root_dir/\/c\//C:\/}

splunk_version_file="$root_dir/splunk-ver"

splunk_version=$(grep -o '^[^#]*' "$splunk_version_file")  # load file and remove comments/blank lines
splunk_version="$(echo -e "$splunk_version" | sed -e 's/[[:space:]]*$//')" || exit 1  # remove trailing whitespace
splunk_version_number=$(echo "$splunk_version" | cut -d- -f1)  # get part after the dash (-)

echo "$splunk_version"
echo "$splunk_version_number"

docker build -t splunkforwarder --build-arg version="$splunk_version" --build-arg version_number="$splunk_version_number" "$root_dir"
