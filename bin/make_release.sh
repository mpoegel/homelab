#!/bin/bash

function log_error {
    echo $1
    exit 1
}

function log_info {
    echo $1
}

TEMP=$(getopt -o "cd" --long "clean,dry-run" -n "make_release.sh" -- "$@")
eval set -- "$TEMP"
unset TEMP

DRY_RUN_MODE=0
CLEAN=0

while true; do
    case "$1" in
        "-c"|"--clean")
            CLEAN=1
            shift
            continue
        ;;
        "-d"|"--dry-run")
            DRY_RUN_MODE=1
            shift
            continue
        ;;
        "--")
            shift
            break
        ;;
        *)
            log_error "Internal error!"
        ;;
    esac
done

# must be run from repo root
if [ ! -d ".git" ]; then
    log_error "please run from the repo root"
fi

# check prerequisites
if [ ! -f ".manifest" ]; then
    log_error ".manifest file not found"
fi

if [ "1" == "$CLEAN" ]; then
    rm -rf dist
fi

mkdir -p dist
distContents=$(ls -A "dist")
if [ ! -z "$distContents" ]; then
    log_error "dist directory is not empty"
fi

tag=$(git tag --points-at HEAD)
if [ -z "$tag" ]; then
    log_error "commit does not have tag"
fi

# begin release
log_info "releasing $tag"

# gather artifacts in dist
while read -r line; do
    to_from_files=(${line// / })
    from_file=${to_from_files[0]}
    to_file=${to_from_files[1]}
    if [ ! -f "$from_file" ]; then
        log_error "missing file: $from_file"
    fi

    destDir=$(dirname "$to_file")
    mkdir -p "dist/$destDir"
    cp $from_file "dist/$to_file"
    if [ ! -f "dist/$to_file" ]; then
        log_error "failed to prepare file: $from_file"
    fi
    log_info "prepared $from_file"
done < ".manifest"

# bundle the dist directory
projectName=$(basename $PWD)
releaseName="${projectName}_$tag"
bundleName="${releaseName}.tar.gz"
tar czf "$bundleName" -C dist .
if [ ! -f "$bundleName" ]; then
    log_error "failed to create release bundle"
fi
log_info "created release bundle $bundleName"

# create github release
if [ "0" == "$DRY_RUN_MODE" ]; then
    gh release create "$tag" --generate-notes "$bundleName"
    log_info "github release completed"
else
    log_info "skipping github release"
fi