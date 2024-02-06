#!/bin/bash
flannel_version=$(yq '.flannel.image.tag' packages/rke2-canal/charts/values.yaml)
echo "$flannel_version $1"
if [ "$flannel_version" != "$1" ]; then
	yq -i ".flannel.image.tag = \"$1\"" packages/rke2-canal/charts/values.yaml
	package_version=$(yq '.packageVersion' packages/rke2-canal/package.yaml)
	new_version=$(printf "%02d" $(($package_version + 1)))
	yq -i ".packageVersion = \"$new_version\"" packages/rke2-canal/package.yaml
fi
