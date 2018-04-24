#!/bin/bash
set -e
set -o pipefail

BIN_DIR="$(cd $(dirname "$0") && pwd)/.bin"
TMP_DIR="$BIN_DIR/tmp"

function main () {
  mkdir -vp "$BIN_DIR" "$TMP_DIR"
  assert_command_is_available jq
  assert_command_is_available curl
  assert_command_is_available unzip

  echo "This script will download the following tools into $BIN_DIR"
  check_the_latest_version kubectl    "$(curl -sS https://storage.googleapis.com/kubernetes-release/release/stable.txt)"
  check_the_latest_version kops       "$(curl -sS https://api.github.com/repos/kubernetes/kops/releases/latest | jq -r .tag_name)"
  check_the_latest_version helm       "$(curl -sS https://api.github.com/repos/kubernetes/helm/releases/latest | jq -r .tag_name)"
  check_the_latest_version helmfile   "$(curl -sS https://api.github.com/repos/roboll/helmfile/releases/latest | jq -r .tag_name)"
  check_the_latest_version terraform  "$(curl -sS https://api.github.com/repos/hashicorp/terraform/releases/latest | jq -r .tag_name | sed -e 's/^v//')"

  echo
  echo -n 'Press enter to install components (ctrl-c to stop): '
  read
  install_binary   kubectl    "https://storage.googleapis.com/kubernetes-release/release/${kubectl_version}/bin/linux/amd64/kubectl"
  install_binary   kops       "https://github.com/kubernetes/kops/releases/download/${kops_version}/kops-linux-amd64"
  install_from_tgz helm       "https://storage.googleapis.com/kubernetes-helm/helm-${helm_version}-linux-amd64.tar.gz" linux-amd64/helm
  install_binary   helmfile   "https://github.com/roboll/helmfile/releases/download/${helmfile_version}/helmfile_darwin_amd64"
  install_from_zip terraform  "https://releases.hashicorp.com/terraform/${terraform_version}/terraform_${terraform_version}_linux_amd64.zip" terraform
}

function check_the_latest_version () {
  name="$1"
  version="$2"
  if [ -z "$version" ]; then
    echo "Could not get the latest version of $name"
    exit 1
  fi
  eval "${name}_version"="$version"
  echo "- $name $version"
}

function install_binary () {
  name="$1"
  url="$2"
  if [ ! -f "$BIN_DIR/$name" ]; then
    echo "Downloading $url"
    curl -L -o "$BIN_DIR/$name" "$url"
    echo "Installing $name"
    chmod +x "$BIN_DIR/$name"
  else
    echo "SKIP: $name is already installed in $BIN_DIR"
  fi
}

function install_from_tgz () {
  name="$1"
  url="$2"
  path="$3"
  if [ ! -f "$BIN_DIR/$name" ]; then
    echo "Downloading $url"
    curl -L -o "$TMP_DIR/$name.tgz" "$url"
    echo "Installing $name"
    mkdir -p "$TMP_DIR/$name"
    tar -C "$TMP_DIR/$name" -x -z -f "$TMP_DIR/$name.tgz" "$path"
    mv "$TMP_DIR/$name/$path" "$BIN_DIR/$name"
    rm "$TMP_DIR/$name.tgz"
  else
    echo "SKIP: $name is already installed in $BIN_DIR"
  fi
}

function install_from_zip () {
  name="$1"
  url="$2"
  path="$3"
  if [ ! -f "$BIN_DIR/$name" ]; then
    echo "Downloading $url"
    curl -L -o "$TMP_DIR/$name.zip" "$url"
    echo "Installing $name"
    mkdir -p "$TMP_DIR/$name"
    unzip -d "$TMP_DIR/$name" "$TMP_DIR/$name.zip" "$path"
    mv "$TMP_DIR/$name/$path" "$BIN_DIR/$name"
    rm "$TMP_DIR/$name.zip"
  else
    echo "SKIP: $name is already installed in $BIN_DIR"
  fi
}

function assert_command_is_available () {
  local command="$1"
  if ! which "$command" > /dev/null; then
    echo "ERROR: $command not found. Please install $command as follows:"
    echo "  (Linux) sudo apt install $command"
    echo "  (macOS) brew install $command"
    exit 1
  fi
}

main
