#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
export SCRIPT_DIR
DEBIAN_FRONTEND=noninteractive
export DEBIAN_FRONTEND
DEBCONF_NONINTERACTIVE_SEEN=true
export DEBCONF_NONINTERACTIVE_SEEN

echo "Updating Locale..."
export LANG=en_US.UTF-8
sudo sed -i -e "s/# $LANG.*/$LANG UTF-8/" /etc/locale.gen
sudo dpkg-reconfigure --frontend=noninteractive locales
sudo update-locale LANG=$LANG

echo "Pre-Configuring TimeZone..."
printf "tzdata tzdata/Areas select US\ntzdata tzdata/Zones/US select Central\n" | sudo debconf-set-selections

if [ -z "$(find /var/cache/apt/pkgcache.bin -mmin -60 &>/dev/null)" ]; then
  echo "Stale package cache, updating..."
  sudo apt-get -qq update
fi

sudo apt-get -qq install -o=Dpkg::Use-Pty=0 --no-install-recommends -y apt-utils tzdata git
sudo dpkg-reconfigure -fnoninteractive tzdata

function apt_install {
  echo "Installing packages [$@]"
  sudo apt-get -qq install -o=Dpkg::Use-Pty=0 --no-install-recommends -y $@ > /dev/null
}
export apt_install

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
JQ_RELEASE_VERSION=$(git -c 'versionsort.suffix=-' ls-remote --tags --sort='v:refname' https://github.com/jqlang/jq.git | grep -v rc | tail --lines=1 | cut --delimiter='/' --fields=3)
curl -SsL "https://github.com/jqlang/jq/releases/download/${JQ_RELEASE_VERSION}/jq-linux-amd64" -o "${BINDIR}/jq"


echo "Installing Shellcheck..."
curl -SsL "https://github.com/koalaman/shellcheck/releases/download/stable/shellcheck-stable.linux.x86_64.tar.xz" | tar -xJvf - -C "${BINDIR}/" --strip-components=1 --wildcards '*/shellcheck'


# Check if using a Jetbrains IDE
if [ -n "${JETBRAINS_IDE_ID}" ]; then
  echo "Checking for Jetbrains language specific personalizations..."
  JETBRAINS_PERSONALIZATION_SCRIPT="${SCRIPT_DIR}/.personalize/${JETBRAINS_IDE_ID}.sh"
  # Check if there is a Jetbrains customization script
  if [ -f "${JETBRAINS_PERSONALIZATION_SCRIPT}" ]; then
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