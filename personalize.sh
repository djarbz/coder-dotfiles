#!/usr/bin/env bash

# If running bash
# if [ -n "$BASH_VERSION" ]; then
#     # If there is a local rc folder, run them.
#     if [ -d ~/.bashrc.local ]; then
#         for rc in ~/.bashrc.local/*; do
#             if [ -f "$rc" ]; then
#             . "$rc"
#             fi
#         done
#     fi

#     unset rc
# fi
BINDIR="$HOME/.local/bin"
mkdir -p "${BINDIR}"

## JQ
echo "Installing JQ..."
JQ_RELEASE_VERSION=$(git -c 'versionsort.suffix=-' ls-remote --tags --sort='v:refname' https://github.com/jqlang/jq.git | grep -v rc | tail --lines=1 | cut --delimiter='/' --fields=3)
curl -Ls https://github.com/jqlang/jq/releases/download/${JQ_RELEASE_VERSION}/jq-linux-amd64 -o "${BINDIR}/jq"


echo "Installing Shellcheck..."
mkdir -p "$HOME/.local/bin/"
curl -Ls https://github.com/koalaman/shellcheck/releases/download/stable/shellcheck-stable.linux.x86_64.tar.xz | tar -xJvf - -C "${BINDIR}/" --strip-components=1 --wildcards */shellcheck


echo "Installing Golang..."
    # Remove the systemwide version of GO
if [ -d /usr/local/go ]; then
  sudo rm -rf /usr/local/go
fi

# If Go is installed, we will find it here.
if [ -d $HOME/go/ ]; then
  export GOROOT=$(find $HOME/go/ -maxdepth 1 -type d -name 'go*' -print | sort -V | tail -n1)
fi

# Install Golang if not already installed.
if ! command -v "${GOROOT}/bin/go" &> /dev/null; then
  echo "Installing Golang"
  GITHUB_REPO="golang/go"
  GITHUB_RELEASE_VERSION=$(git -c 'versionsort.suffix=-' ls-remote --tags --sort='v:refname' https://github.com/${GITHUB_REPO}.git | grep 'refs/tags/go' | grep -v rc | tail --lines=1 | cut --delimiter='/' --fields=3)
  export GOROOT="$HOME/go/${GITHUB_RELEASE_VERSION}/"
  mkdir -p "${GOROOT}"
  mkdir -p "$HOME/go/bin"
  curl -Ls "https://go.dev/dl/${GITHUB_RELEASE_VERSION}.linux-amd64.tar.gz" | tar -xzf - -C "${GOROOT}" --strip-components=1
fi
# Ensure that GOROOT is set to an actual directory.
if [ -d $HOME/go/ ]; then
  export GOROOT=$(find $HOME/go/ -maxdepth 1 -type d -name 'go*' -print | sort -V | tail -n1)
else
  echo "!!! Golang is not installed !!!"
fi

if command -v go &> /dev/null; then
  NEWBIN="$(go env GOPATH)/bin"
  if ! [[ "$PATH" =~ "$NEWBIN" ]]; then
    [ -d "$NEWBIN" ] && PATH="$NEWBIN:$PATH"
  fi
fi

export PATH

if command -v go &> /dev/null; then
    go install golang.org/x/tools/cmd/goimports@latest
    go install github.com/fzipp/gocyclo/cmd/gocyclo@latest
    curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b "$(go env GOPATH)/bin" v1.46.1
    go install -v github.com/go-critic/go-critic/cmd/gocritic@latest
    go install github.com/spf13/cobra-cli@latest
    go install github.com/swaggo/swag/cmd/swag@latest
fi


# Prep cloned workspace via any found `coder.bootstrap` executable files in the project directory.
if [ -v PROJECT_DIRECTORY ]; then
    echo "Prepping Project Workspace..."
    find "${PROJECT_DIRECTORY}" -name coder.bootstrap -type f -executable -print -exec {} \;
fi