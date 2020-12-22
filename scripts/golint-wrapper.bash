#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail +o xtrace

exit_code=0
while read issue; do
	if [[ ${issue} =~ ^(.*/)?internal/.*\.go: ]]; then
		if [[ ${issue} =~ should\ have\ comment\ or\ be\ unexported ]]; then
			continue
		fi
	fi
	echo "${issue}"
	exit_code=1
done < <("${GOLINT}" "$@")
exit ${exit_code}
