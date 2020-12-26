#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

exit_code=0
while read suggestion; do
	if [[ ${suggestion} =~ ^(.*/)?internal/.*\.go: ]]; then
		# go file in internal package
		if [[ ${suggestion} =~ should\ have\ comment\ or\ be\ unexported ]]; then
			# ignore this suggestion
			continue
		fi
	fi
	echo "${suggestion}"
	exit_code=1
done
exit ${exit_code}
