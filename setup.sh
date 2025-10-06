#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
export SCRIPT_DIR
DEBIAN_FRONTEND=noninteractive
export DEBIAN_FRONTEND
DEBCONF_NONINTERACTIVE_SEEN=true
export DEBCONF_NONINTERACTIVE_SEEN

# Determine if we need to prefix commands with sudo
SUDO=""
if [ "$(id -u)" -ne 0 ]; then
  SUDO="sudo"
fi

# Exit on error, undefined variables, and pipe failures
set -euo pipefail

# sleep 10
# # Wait until no files matching the pattern exist
# while find /tmp -maxdepth 1 -name 'kasmvncserver.*' ! -name '*.log' 2>/dev/null | grep -q .; do
#   sleep 1
# done

echo 'debconf debconf/frontend select Noninteractive' | ${SUDO} debconf-set-selections

function apt_install {
  # Define the directory to check
  CACHE_DIR="/var/lib/apt/lists/partial"
  # Determine if we need to prefix commands with sudo
  SUDO=""
  if [ "$(id -u)" -ne 0 ]; then
    SUDO="sudo"
  fi
  # Check if the directory exists and was modified in the last 60 minutes
  if [ ! -d "$CACHE_DIR" ] || ! find "$CACHE_DIR" -mmin -60 -print -quit &>/dev/null; then
    echo "Stale Package Cache, updating..."
    # Update package cache with a 300-second timeout for dpkg lock
    ${SUDO} apt-get -o DPkg::Lock::Timeout=300 -qq update
  fi

  echo "Installing packages [$*]"
  ${SUDO} apt-get -o DPkg::Lock::Timeout=300 install -o=Dpkg::Use-Pty=0 --no-install-recommends -yqq "$@" > /dev/null
}
export apt_install

echo "Updating Locale..."
start_time=$SECONDS
export LANG=en_US.UTF-8
${SUDO} sed -i -e "s/# $LANG.*/$LANG UTF-8/" /etc/locale.gen
echo 'locales locales/default_environment_locale select en_US.UTF-8' | ${SUDO} debconf-set-selections
${SUDO} update-locale LANG=$LANG
elapsed_seconds=$((SECONDS - start_time))
echo "Execution time: $elapsed_seconds seconds"

# echo "Pre-Configuring TimeZone..."
# printf "tzdata tzdata/Areas select US\ntzdata tzdata/Zones/US select Central\n" | ${SUDO} debconf-set-selections
echo 'tzdata tzdata/Areas select America' | ${SUDO} debconf-set-selections
echo 'tzdata tzdata/Zones/America select Chicago' | ${SUDO} debconf-set-selections

echo "Installing packages..."
start_time=$SECONDS
apt_install apt-utils tzdata git xz-utils
${SUDO} apt-get -o DPkg::Lock::Timeout=300 install --reinstall -o=Dpkg::Use-Pty=0 --no-install-recommends -yqq locales
elapsed_seconds=$((SECONDS - start_time))
echo "Execution time: $elapsed_seconds seconds"

BINDIR="$HOME/.local/bin"
export BINDIR
mkdir -p "${BINDIR}"

# Add local bin dir to PATH
if ! [[ "${PATH}" =~ ${BINDIR} ]]; then
  [ -d "${BINDIR}" ] && PATH="${BINDIR}:${PATH}"
fi
export PATH

## JQ
echo "Installing JQ..."
start_time=$SECONDS
JQ_RELEASE_VERSION=$(git -c 'versionsort.suffix=-' ls-remote --tags --sort='v:refname' https://github.com/jqlang/jq.git | grep -v rc | tail --lines=1 | cut --delimiter='/' --fields=3)
curl -SsL "https://github.com/jqlang/jq/releases/download/${JQ_RELEASE_VERSION}/jq-linux-amd64" -o "${BINDIR}/jq"
elapsed_seconds=$((SECONDS - start_time))
echo "Execution time: $elapsed_seconds seconds"


echo "Installing Shellcheck..."
start_time=$SECONDS
curl -SsL "https://github.com/koalaman/shellcheck/releases/download/stable/shellcheck-stable.linux.x86_64.tar.xz" | tar -xJvf - -C "${BINDIR}/" --strip-components=1 --wildcards '*/shellcheck'
elapsed_seconds=$((SECONDS - start_time))
echo "Execution time: $elapsed_seconds seconds"

# Update and apply changes to workspace repository
# if [ -v PROJECT_DIRECTORY ]; then
#   echo "Checking for project updates in ${PROJECT_DIRECTORY}"

#   # Capture the current branch name
#   current_branch=$(git -C "${PROJECT_DIRECTORY}" rev-parse --abbrev-ref HEAD || { echo "Failed to get current branch"; exit 1; })

#   # Sync remote changes
#   if ! git -C "${PROJECT_DIRECTORY}" fetch origin; then
#     echo "Failed to fetch from origin"
#     exit 1
#   fi

#   # Fast-forward merge updates if no conflicts
#   if ! git -C "${PROJECT_DIRECTORY}" merge --ff-only "origin/${current_branch}"; then
#     echo "Failed to fast-forward merge on branch ${current_branch}"
#     exit 1
#   fi

#   echo "Project updated successfully on branch ${current_branch}"
# fi

# Check if using a Jetbrains IDE
start_time=$SECONDS
if [ -v JETBRAINS_IDE_ID ]; then
  echo "Checking for Jetbrains language specific personalizations..."
  JETBRAINS_PERSONALIZATION_SCRIPT="${SCRIPT_DIR}/.personalize/${JETBRAINS_IDE_ID}.sh"
  # Check if there is a Jetbrains customization script
  if [ -f "${JETBRAINS_PERSONALIZATION_SCRIPT}" ]; then
    echo "Applying Jetbrains [${JETBRAINS_IDE_ID}] config..."
    # shellcheck disable=SC1090
    source "${JETBRAINS_PERSONALIZATION_SCRIPT}"
  else
    echo "Jetbrains personalization script not found!"
  fi
fi
elapsed_seconds=$((SECONDS - start_time))
echo "Execution time: $elapsed_seconds seconds"

# Prep cloned workspace via any found `coder.bootstrap` executable files in the project directory.
start_time=$SECONDS
if [ -v PROJECT_DIRECTORY ]; then
  echo "Prepping Project Workspace..."
  find "${PROJECT_DIRECTORY}" -name coder.bootstrap -type f -print -exec bash {} \;
  if [ -d "${PROJECT_DIRECTORY}/.coder/bootstrap.d" ]; then
    find "${PROJECT_DIRECTORY}/.coder/bootstrap.d" -type f -executable -print -exec bash {} \;
  fi
fi
elapsed_seconds=$((SECONDS - start_time))
echo "Execution time: $elapsed_seconds seconds"

# Return to default
echo 'debconf debconf/frontend select Dialog' | ${SUDO} debconf-set-selections
