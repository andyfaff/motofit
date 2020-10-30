#!/bin/bash
# get name of cwd
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"

cd "$DIR"

IPUF=~/Documents/WaveMetrics/Igor\ Pro\ 8\ User\ Files

cp -r "macXOP/Igor Extensions (64-bit)/" "$IPUF/Igor Extensions (64-bit)"
cp -r "Igor Procedures/" "$IPUF/Igor Procedures"
cp -r "User Procedures/" "$IPUF/User Procedures"