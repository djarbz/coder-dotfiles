#!/usr/bin/env bash

set -e

echo "Applying personalization for Goland..."

if [ -d /usr/local/go ]; then
  echo "Removing the systemwide version of GO..."
  sudo rm -rf /usr/local/go
fi

GO_VERSION=$(curl -s 'https://go.dev/VERSION?m=text' | head -n 1)
GOROOT="${HOME}/go/${GO_VERSION}"
GOBIN="${GOROOT}/bin/go"
mkdir -p "${GOROOT}"
mkdir -p "${HOME}/go/{bin,pkg,src}"

echo "Checking if Userland Go $GO_VERSION is installed..."
if [ ! -x "$GOBIN" ]; then
  echo "Installing Userland Golang $GO_VERSION..."
  curl -SsL "https://go.dev/dl/${GO_VERSION}.linux-amd64.tar.gz" | tar -xzf - -C "${GOROOT}" --strip-components=1
fi

echo "Validating userland Go $GO_VERSION..."
if [ ! -x "$GOBIN" ]; then
  echo "!!! Userland Go is not installed correctly !!!"
  exit 1
fi

echo "Adding GO Bin to PATH..."
GOROOT="$("${GOBIN}" env GOROOT)"
NEWBIN="${GOROOT}/bin"
if ! [[ "${PATH}" =~ ${NEWBIN} ]]; then
  [ -d "${NEWBIN}" ] && PATH="${NEWBIN}:${PATH}"
fi

export PATH
export GOROOT

cat << 'EOF' | sudo tee /etc/profile.d/golang.sh > /dev/null
#!/usr/bin/env bash
# Set $GOROOT and update $PATH for Golang

GOROOT=$(find "${HOME}/go" -maxdepth 1 -type d -name 'go*' -print | sort -V | tail -n1)

# Exit early if no $GOROOT found
if [ -z "${GOROOT}" ]; then
  echo "!!! No Go installation found in ${HOME}/go !!!"
  exit 0
fi

# Verify that $GOROOT/bin/go is executable
if [ ! -x "${GOROOT}/bin/go" ]; then
  echo "!!! Go binary not found or not executable in ${GOROOT}/bin !!!"
  exit 0
fi

export GOROOT

# Add $GOROOT/bin to PATH if not already present
GOBIN="${GOROOT}/bin"
if ! [[ "${PATH}" =~ "${GOROOT}/bin" ]]; then
  [ -d "${GOBIN}" ] && PATH="${GOBIN}:${PATH}"
  export PATH
fi

# Add $HOME/go/bin to PATH if not already present
GOBIN="$HOME/go/bin"
if ! [[ "$PATH" =~ "${GOBIN}" ]]; then
  [ -d "${GOBIN}" ] && PATH="${GOBIN}:${PATH}"
  export PATH
fi

EOF

# Ensure the script has execute permissions
sudo chmod +x /etc/profile.d/golang.sh

echo "Profile script created and permissions set."

echo "Installing common GOLANG packages and tooling..."

go install golang.org/x/tools/cmd/goimports@latest
go install github.com/fzipp/gocyclo/cmd/gocyclo@latest
curl -fSsL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b "$("${GOBIN}" env GOPATH)/bin" v1.46.1
go install -v github.com/go-critic/go-critic/cmd/gocritic@latest
go install github.com/spf13/cobra-cli@latest
go install github.com/swaggo/swag/cmd/swag@latest

echo "Golang setup completed successfully!"
