#!/bin/bash -x

. convertLocalMode.conf

if [ -z "$GIT_ROOT" ]; then
    echo "Set a git repository first"
    exit 1
fi