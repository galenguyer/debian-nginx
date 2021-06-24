#!/usr/bin/env bash
# build, tag, and push docker images

# exit if a command fails
set -o errexit

# exit if required variables aren't set
set -o nounset

# check for docker
if command -v docker 2>&1 >/dev/null; then
	echo "using docker..."
else
	echo "could not find docker, exiting"
	exit 1
fi

# retrieve latest nginx mainline version
nginx_mainline="$(curl -sSL https://nginx.org/en/download.html | grep -P '(\/download\/nginx-\d+\.\d+\.\d+\.tar\.gz)' -o | uniq | head -n1 | grep -o -P '\d+\.\d+\.\d+')"
echo "using nginx mainline version $nginx_mainline..."

# pass core count into container for build process
core_count="$(nproc)"
echo "using $core_count cores..."

export CORE_COUNT="$core_count"
export NGINX_MAINLINE="$nginx_mainline"
docker buildx bake "$@"
