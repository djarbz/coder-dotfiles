#!/usr/bin/env bash

echo "Applying personalization for Goland..."

echo "Removing the systemwide version of GO..."
if [ -d /usr/local/go ]; then
  sudo rm -rf /usr/local/go
fi

echo "Checking for userland GOROOT..."
if [ -d "${HOME}/go" ]; then
  echo "Userland GOROOT exists..."
  GOROOT=$(find "${HOME}/go" -maxdepth 1 -type d -name 'go*' -print | sort -V | tail -n1)
fi

echo "Checking if Userland GO is installed..."
if ! command -v "${GOROOT}/bin/go" &> /dev/null; then
  echo "Installing Userland Golang..."
  GITHUB_REPO="golang/go"
  GITHUB_RELEASE_VERSION=$(
    git \
    -c 'versionsort.suffix=-' \
    ls-remote \
    --tags \
    --sort='v:refname' \
    "https://github.com/${GITHUB_REPO}.git" \
    | grep 'refs/tags/go' \
    | grep -v rc \
    | tail --lines=1 \
    | cut --delimiter='/' --fields=3\
  )
  GOROOT="$HOME/go/${GITHUB_RELEASE_VERSION}"
  mkdir -p "${GOROOT}"
  mkdir -p "${HOME}/go/bin"
  curl -SsL "https://go.dev/dl/${GITHUB_RELEASE_VERSION}.linux-amd64.tar.gz" | tar -xzf - -C "${GOROOT}" --strip-components=1

  echo "Validating userland GOROOT..."
  if [ -d "${HOME}/go" ]; then
    echo "Userland GOROOT exists..."
    GOROOT=$(find "${HOME}/go" -maxdepth 1 -type d -name 'go*' -print | sort -V | tail -n1)
  else
    echo "!!! Userland GOROOT does not exist !!!"
    exit 1
  fi
fi

if ! command -v "${GOROOT}/bin/go" &> /dev/null; then
  echo "!!! Golang is not installed !!!"
  exit 1
fi

echo "Adding GO Bin to PATH..."
NEWBIN="$(go env GOPATH)/bin"
if ! [[ "${PATH}" =~ ${NEWBIN} ]]; then
  [ -d "${NEWBIN}" ] && PATH="${NEWBIN}:${PATH}"
fi

export PATH
export GOROOT

echo "Installing common GOLANG packages and tooling..."
go install golang.org/x/tools/cmd/goimports@latest
go install github.com/fzipp/gocyclo/cmd/gocyclo@latest
curl -fSsL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b "$(go env GOPATH)/bin" v1.46.1
go install -v github.com/go-critic/go-critic/cmd/gocritic@latest
go install github.com/spf13/cobra-cli@latest
go install github.com/swaggo/swag/cmd/swag@latest