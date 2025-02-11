#!/bin/bash
set -eux

source $(dirname $0)/create-issue.sh

LABEL="area/cni"
ISSUE_TITLE="Updatecli failed for multus ${MULTUS_VERSION}"
CHART_VERSION=""
trap report-error EXIT INT

new_package=false
if [ -n "$CNI_PLUGINS_VERSION" ]; then
	current_cni_plugins_version=$(yq '.cniplugins.image.tag' packages/rke2-multus/charts/values.yaml)
	if [ "$current_cni_plugins_version" != "$CNI_PLUGINS_VERSION" ]; then
		echo "Updating CNI plugin version to $CNI_PLUGINS_VERSION"
		sed -i "s/$current_cni_plugins_version/$CNI_PLUGINS_VERSION/g" packages/rke2-multus/charts/values.yaml
		package_version=$(yq '.packageVersion' packages/rke2-multus/package.yaml)
		new_version=$(printf "%02d" $(($package_version + 1)))
		yq -i ".packageVersion = $new_version" packages/rke2-multus/package.yaml
		new_package=true
		current_multus_version=$(yq '.image.tag' packages/rke2-multus/charts/values.yaml)
		current_app_version=$(echo "$current_multus_version" | grep -Eo '^v*[0-9]+.[0-9]+.[0-9]+')
		CHART_VERSION="${current_app_version}${new_version}"
	fi
fi
if [ -n "$MULTUS_VERSION" ]; then
	app_version=$(echo "$MULTUS_VERSION" | grep -Eo '^v*[0-9]+.[0-9]+.[0-9]+' | tr -d 'v')
	current_multus_version=$(yq '.image.tag' packages/rke2-multus/charts/values.yaml)
	current_app_version=$(echo "$current_multus_version" | grep -Eo '^v*[0-9]+.[0-9]+.[0-9]+' | tr -d 'v')
	if [ "$current_multus_version" != "$MULTUS_VERSION" ]; then
		echo "Updating Multus chart to $MULTUS_VERSION"
		if [ "$app_version" != "$current_app_version" ]; then
			sed -i "s/version: .*/version: v$app_version/g" packages/rke2-multus/charts/Chart.yaml
			sed -i "s/appVersion: .*/appVersion: $app_version/g" packages/rke2-multus/charts/Chart.yaml
			sed -i "s/  tag: $current_multus_version/  tag: $MULTUS_VERSION/g" packages/rke2-multus/charts/values.yaml
			sed -i "s/  tag: $current_app_version/  tag: $app_version/g" packages/rke2-multus/charts/values.yaml
			yq -i ".packageVersion = 00" packages/rke2-multus/package.yaml
			CHART_VERSION="v${app_version}00"
		else
			sed -i "s/  tag: $current_multus_version/  tag: $MULTUS_VERSION/g" packages/rke2-multus/charts/values.yaml
			if [ "$new_package" = false ]; then
				package_version=$(yq '.packageVersion' packages/rke2-multus/package.yaml)
				new_version=$(printf "%02d" $(($package_version + 1)))
				yq -i ".packageVersion = $new_version" packages/rke2-multus/package.yaml
				CHART_VERSION="v${current_app_version}${new_version}"
			fi
		fi
	fi
fi
if [ -n "$CHART_VERSION" ]; then
	ISSUE_TITLE="Update Multus to ${CHART_VERSION}"
	create_rke2_issue
fi
