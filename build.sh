#!/bin/bash

root_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
root_dir=${root_dir/\/cygdrive\/c\//C:\/}
root_dir=${root_dir/\/c\//C:\/}

docker build -t splunkforwarder "$root_dir"
