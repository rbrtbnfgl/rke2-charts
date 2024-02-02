#!/bin/bash
flannel_version=$(yq '.flannel.image.tag' packages/rke2-canal/charts/values.yaml)
echo "$flannel_version $1"
if [ "$flannel_version" != "$1" ]; then
	yq -i '.flannel.image.tag = $flannel_version' packages/rke2-canal/charts/values.yaml
fi
