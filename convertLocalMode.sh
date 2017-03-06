#!/bin/bash -x

. convertLocalMode.conf

if [ -z "$GIT_ROOT" ]; then
    echo "Set a git repository first"
    exit 1
fi

while IFS= read -r -d '' repo_source
do
    echo $repo_source

done <   <(find "$GIT_ROOT" -iname "*.git" -print0)