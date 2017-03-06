#!/bin/bash -x

. convertLocalMode.conf

if [ -z "$GIT_REPO" ]; then
    echo "Set a git repository first"
    exit 1
fi

if [ ! -d "$CONVERT_REPO" ]; then
    echo "Convert target directory misingh : $CONVERT_REPO"
    exit 1
fi


while IFS= read -r -d '' repo_source
do
    echo "$repo_source"
    repo_name=$(basename "$repo_source" .git)
    repo_convert="$CONVERT_REPO/$repo_name.git"

    if [ ! -d "$repo_source" ]; then
            echo "No repo source set"
            exit 1;
    fi

    #trim space : http://stackoverflow.com/questions/20600982/remove-leading-and-trailing-space-in-field-in-awk
    #parse ini : http://stackoverflow.com/questions/6318809/how-do-i-grab-an-ini-value-within-a-shell-script
    svn_file_def="$repo_source/svn/.svngit/svngitkit.config"

    if [ ! -f "$svn_file_def" ]; then
            echo "No svn project set"
            exit 1;
    fi
    svn_path=$(awk -F "=" '/translation-root/ {gsub(/ /,"",$2); print $2}'  "$svn_file_def")

    ## GENERATE svn remote git copy
    subgit configure "$SVN_URL/$svn_path" "$repo_convert"

    if [ -n "$SVN_SUBGIT_USER" ] && [ -n "$SVN_SUBGIT_PASSWORD" ]; then
        echo "$SVN_SUBGIT_USER $SVN_SUBGIT_PASSWORD" > "$repo_convert/subgit/passwd"
    fi

    sed \
        -e "s#shared =.*#shared = true#" \
        -e "s#subversionConfigurationDirectory =.*#subversionConfigurationDirectory = $PROJECT_ROOT/.subversion#" \
        -i \
        "$repo_convert/subgit/config"

    if [ -n "$SUBGIT_AUTHORS_FILE" ]; then
        sed \
            -e "s#authorsFile =.*#authorsFile = $SUBGIT_AUTHORS_FILE#"
    fi
    
    subgit install "$repo_convert"
    subgit shutdown "$repo_convert"

    ## OVERRIDE WITH OLD SHA-1
    cp -far "$repo_source/objects" "$repo_convert/"

    ## Manage svn data
    rm -fr "$repo_convert/svn/refs/svn/root"
    cp -far "$repo_source"/svn/refs/svn/root/"$svn_path" "$repo_convert"/svn/refs/svn/root
    cp -far "$repo_source"/svn/.metadata "$repo_convert"/svn/

    ## Manage refs
    cp -far "$repo_source"/refs "$repo_convert"/
    rm -fr "$repo_convert"/refs/svn/{root,attic}
    cp -far "$repo_source"/refs/svn/root/"$svn_path" "$repo_convert"/refs/svn/root
    cp -far "$repo_source"/refs/svn/attic/"$svn_path" "$repo_convert"/refs/svn/attic

    git --git-dir="$repo_convert" fetch --force "$repo_source" refs/svn/map:refs/svn/map

    ## Get packed refs (if existing)
    rm "$repo_convert"/packed-refs
    cp -bar "$repo_source"/packed-refs "$repo_convert"/packed-refs

    ##Remove remotes
    git --git-dir="$repo_convert" branch -rd "$(git --git-dir=$repo_convert branch -r)"

    subgit fetch "$repo_convert"
    subgit uninstall "$repo_convert"

done <   <(find "$GIT_REPO" -iname "*.git" -print0)