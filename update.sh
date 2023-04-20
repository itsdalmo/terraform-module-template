#!/usr/bin/env bash

set -euo pipefail

SRC=$PWD
REF=$(git merge-base master add-update-script | cut -c 1-7 | tr -d '\n')

main() {
	set +u
	DIR="${1}"
	set -u

	if [ ! -d "${DIR}" ]; then
		echo "usage: ./update.sh DIRECTORY"
		exit 1
	fi

	cd "${DIR}"
	git checkout master
	git pull

	if [ ! -d "${DIR}/.github" ]; then
		# Copy entire directory if it does not exist.
		cp -r "${SRC}/.github" "${DIR}/.github"
	else
		# Reset ISSUE_TEMPLATE and workflow
		rm -rf "${DIR}/.github/ISSUE_TEMPLATE"
		rm -rf "${DIR}/.github/workflows"

		cp -r "${SRC}/.github/ISSUE_TEMPLATE" "${DIR}/.github/ISSUE_TEMPLATE"
		cp -r "${SRC}/.github/workflows" "${DIR}/.github/workflows"
	fi

	if [ -f "${DIR}/CODEOWNERS" ]; then
		# Move existing CODEOWNERS to .github
		mv "${DIR}/CODEOWNERS" "${DIR}/.github/CODEOWNERS"
	elif [ ! -f "${DIR}/.github/CODEOWNERS" ]; then
		# Copy template if it does not exist at all
		cp "${SRC}/.github/CODEOWNERS" "${DIR}/.github/CODEOWNERS"
	fi

	# Update .gitignore
	cp "${SRC}/.gitignore" "${DIR}/.gitignore"

	# Update taskfile
	cp "${SRC}/Taskfile.yml" "${DIR}/Taskfile.yml"

	# Add a license if missing
	if [ ! -f "${DIR}/LICENSE" ]; then
		cp "${SRC}/LICENSE" "${DIR}/LICENSE"
	fi

	# Remove unused files
	set +e
	for f in .travis.yml Makefile STYLE.md CONTRIBUTING.md .github/PULL_REQUEST_TEMPLATE.md; do
		rm "${DIR}/${f}" 2>/dev/null
	done

	# Remove old test harness
	rm -rf "${DIR}/.ci" 2>/dev/null
	for f in "${DIR}"/examples/*/test.sh; do
		rm "${f}" 2>/dev/null
	done
	set -e

	# Delete terraform lock files
	find . -name '.terraform.lock.hcl' -type f -delete

	# Add a readme if missing
	if [ ! -f "${DIR}/README.md" ]; then
		cp "${SRC}/README.md" "${DIR}/README"
	fi

	# Remove maintained shield from README.
	sed -i '' -E "/.*img\.shields\.io\/maintenance\/yes.*/d" "${DIR}/README.md"

	# Update build/release badges
	python3 "${SRC}/update_badges.py" --path "${DIR}/README.md"

	# Add terratest scaffold if missing
	if [ ! -d "${DIR}/test" ]; then
		cp -r "${SRC}/test" "${DIR}/test"
	fi

	# Fix go module
	if [ ! -f "${DIR}/go.mod" ]; then
		go mod init
	fi
	# Build (update dependencies) and tidy
	go build ./test
	go mod tidy

	# Add examples if missing
	for d in examples/basic examples/complete; do
		if [ ! -d "${DIR}/${d}" ]; then
			set +e
			rm -rf "${SRC}/${d}/.terraform" && rm "${SRC}/${d}/terraform.tfstate*"
			set -e
			cp -r "${SRC}/${d}" "${DIR}/${d}"
		else
			cp "${SRC}/${d}/README.md" "${DIR}/${d}/README.md"
		fi
	done

	if [[ -n $(git ls-files -m) ]]; then
		git checkout -B module-template-updates
		git add .
		git commit -m "Updates from module template: ${REF}"
	fi
}

main $1
