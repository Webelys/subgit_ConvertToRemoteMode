#!/bin/bash -x

. convertLocalMode.conf

if [ -z "$GIT_ROOT" ]; then
    echo "Set a git repository first"
    exit 1
fi

while IFS= read -r -d '' repo_source
do
    echo $repo_source
    repo_name=$(basename $repo_source .git)
    repo_convert=$CONVERT_REPO/$repo_name.git

    if [ ! -d "$repo_source" ]; then
            echo "No repo source set"
            exit 1;
    fi

done <   <(find "$GIT_ROOT" -iname "*.git" -print0)