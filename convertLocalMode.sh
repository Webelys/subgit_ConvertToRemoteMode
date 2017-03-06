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

    #trim space : http://stackoverflow.com/questions/20600982/remove-leading-and-trailing-space-in-field-in-awk
    #parse ini : http://stackoverflow.com/questions/6318809/how-do-i-grab-an-ini-value-within-a-shell-script
    svn_file_def="$repo_source/svn/.svngit/svngitkit.config"
    svn_file_metadata="$repo_source/svn/.metadata"

    if [ ! -f "$svn_file_def" ]; then
            echo "No svn project set"
            exit 1;
    fi
    svn_path=$(awk -F "=" '/translation-root/ {gsub(/ /,"",$2); print $2}'  $svn_file_def)

    ## GENERATE svn remote git copy
    subgit configure "$SVN_URL/$svn_path" "$repo_convert"

    echo "$SVN_SUBGIT_USER $SVN_SUBGIT_PASSWORD" > $repo_convert/subgit/passwd

    sed \
            -e "s#shared =.*#shared = true#" \
            -e "s#authorsFile =.*#authorsFile = $PROJECT_ROOT/subgit/authors.sh#" \
            -e "s#subversionConfigurationDirectory =.*#subversionConfigurationDirectory = $PROJECT_ROOT/.subversion#" \
            -i \
            $repo_convert/subgit/config


done <   <(find "$GIT_ROOT" -iname "*.git" -print0)