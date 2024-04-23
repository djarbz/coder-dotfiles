#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

BINDIR="$HOME/.local/bin"
mkdir -p "${BINDIR}"

## JQ
echo "Installing JQ..."
JQ_RELEASE_VERSION=$(git -c 'versionsort.suffix=-' ls-remote --tags --sort='v:refname' https://github.com/jqlang/jq.git | grep -v rc | tail --lines=1 | cut --delimiter='/' --fields=3)
curl -SsL "https://github.com/jqlang/jq/releases/download/${JQ_RELEASE_VERSION}/jq-linux-amd64" -o "${BINDIR}/jq"


echo "Installing Shellcheck..."
mkdir -p "$HOME/.local/bin/"
curl -SsL "https://github.com/koalaman/shellcheck/releases/download/stable/shellcheck-stable.linux.x86_64.tar.xz" | tar -xJvf - -C "${BINDIR}/" --strip-components=1 --wildcards '*/shellcheck'


if [ -n "${JETBRAINS_IDE_ID}" ]; then
  echo "Checking for Jetbrains language specific personalizations..."
  JETBRAINS_PERSONALIZATION_SCRIPT="${SCRIPT_DIR}/.personalize/${JETBRAINS_IDE_ID}.sh"
  # Check if the IDE ID is set AND the expected script is a file AND the file is executable.
  if [ -f "${JETBRAINS_PERSONALIZATION_SCRIPT}" ] && [ -x "${JETBRAINS_PERSONALIZATION_SCRIPT}" ]; then
    echo "Applying Jetbrains [${JETBRAINS_IDE_ID}] config..."
    source "${JETBRAINS_PERSONALIZATION_SCRIPT}"
  else
    echo "Jetbrains personalization script not found!"
  fi
fi


# Prep cloned workspace via any found `coder.bootstrap` executable files in the project directory.
if [ -v PROJECT_DIRECTORY ]; then
  echo "Prepping Project Workspace..."
  find "${PROJECT_DIRECTORY}" -name coder.bootstrap -type f -print -exec bash {} \;
fi