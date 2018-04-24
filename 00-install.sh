#!/bin/bash
set -e
set -o pipefail

BIN_DIR="$(cd "$(dirname "$0")" && pwd)/.bin"
TMP_DIR="$BIN_DIR/tmp"

function main () {
  mkdir -vp "$BIN_DIR" "$TMP_DIR"
  assert_command_is_available jq
  assert_command_is_available curl
  assert_command_is_available unzip

  echo "This script will download tools into $BIN_DIR"

  if need_to_install_command kubectl; then
    local kubectl_version="$(curl -sS https://storage.googleapis.com/kubernetes-release/release/stable.txt)"
    install_from_binary kubectl "https://storage.googleapis.com/kubernetes-release/release/${kubectl_version}/bin/linux/amd64/kubectl"
  fi

  if need_to_install_command kops; then
    local kops_version="$(curl -sS https://api.github.com/repos/kubernetes/kops/releases/latest | jq -r .tag_name)"
    install_from_binary kops "https://github.com/kubernetes/kops/releases/download/${kops_version}/kops-linux-amd64"
  fi

  if need_to_install_command helm; then
    local helm_version="$(curl -sS https://api.github.com/repos/kubernetes/helm/releases/latest | jq -r .tag_name)"
    install_from_tgz helm "https://storage.googleapis.com/kubernetes-helm/helm-${helm_version}-linux-amd64.tar.gz" linux-amd64/helm
  fi

  if need_to_install_command helmfile; then
    local helmfile_version="$(curl -sS https://api.github.com/repos/roboll/helmfile/releases/latest | jq -r .tag_name)"
    install_from_binary helmfile "https://github.com/roboll/helmfile/releases/download/${helmfile_version}/helmfile_darwin_amd64"
  fi

  if need_to_install_command terraform; then
    local terraform_version="$(curl -sS https://api.github.com/repos/hashicorp/terraform/releases/latest | jq -r .tag_name | sed -e 's/^v//')"
    install_from_zip terraform "https://releases.hashicorp.com/terraform/${terraform_version}/terraform_${terraform_version}_linux_amd64.zip" terraform
  fi
}

function install_from_binary () {
  local name="$1"
  local url="$2"
  echo "Downloading $url"
  curl -L -o "$BIN_DIR/$name" "$url"
  echo "Installing $name"
  chmod +x "$BIN_DIR/$name"
}

function install_from_tgz () {
  local name="$1"
  local url="$2"
  local path="$3"
  echo "Downloading $url"
  curl -L -o "$TMP_DIR/$name.tgz" "$url"
  echo "Installing $name"
  mkdir -p "$TMP_DIR/$name"
  tar -C "$TMP_DIR/$name" -x -z -f "$TMP_DIR/$name.tgz" "$path"
  mv "$TMP_DIR/$name/$path" "$BIN_DIR/$name"
  rm "$TMP_DIR/$name.tgz"
}

function install_from_zip () {
  local name="$1"
  local url="$2"
  local path="$3"
  echo "Downloading $url"
  curl -L -o "$TMP_DIR/$name.zip" "$url"
  echo "Installing $name"
  mkdir -p "$TMP_DIR/$name"
  unzip -d "$TMP_DIR/$name" "$TMP_DIR/$name.zip" "$path"
  mv "$TMP_DIR/$name/$path" "$BIN_DIR/$name"
  rm "$TMP_DIR/$name.zip"
}

function need_to_install_command () {
  local name="$1"
  if [ -f "$BIN_DIR/$name" ]; then
    echo "SKIP: $name is already installed as $BIN_DIR/$name"
    return 1
  else
    local existent="$(which "$name" 2> /dev/null)"
    if [ "$existent" ]; then
      echo "SKIP: $name is already installed as $existent"
      return 1
    fi
  fi
}

function assert_command_is_available () {
  local name="$1"
  if ! which "$name" > /dev/null; then
    echo "ERROR: $name not found. Please install $name as follows:"
    echo "  (Linux) sudo apt install $name"
    echo "  (macOS) brew install $name"
    exit 1
  fi
}

main
