#!/bin/bash
set -e
set -o pipefail

BIN_DIR="$HOME/bin"
TMP_DIR="/tmp/kubernetes-toolbox"
versions=()

function main () {
  if ! which jq > /dev/null; then
    echo "ERROR: jq not found. Please install jq as follows:"
    echo "  sudo apt install jq"
    exit 1
  fi
  if ! which curl > /dev/null; then
    echo "ERROR: curl not found. Please install curl as follows:"
    echo "  sudo apt install curl"
    exit 1
  fi
  echo "Destination directory: $BIN_DIR"
  echo "Temporary directory: $TMP_DIR"
  mkdir -vp "$BIN_DIR" "$TMP_DIR"

  case "$(uname)" in
  Darwin)
    install_tools_for_macos;;
  Linux)
    install_tools_for_linux;;
  *)
    echo "Unknown operating system: $(uname)"
    exit 1
    ;;
  esac
}

function install_tools_for_macos () {
  local components=(
    'awscli'
    'kops'
    'terraform'
    'kubernetes-cli'
    'kubernetes-helm'
  )
  for component in ${components[@]}; do
    echo "- $component"
  done
  check_the_latest_version helmfile "$(curl -s https://api.github.com/repos/roboll/helmfile/releases/latest | jq -r .tag_name)"
  echo
  echo -n 'Press enter to install components: '
  read

  brew install "${components[@]}"
  install_binary helmfile "https://github.com/roboll/helmfile/releases/download/${versions['helmfile']}/helmfile_darwin_amd64"
}

function install_tools_for_linux () {
  check_the_latest_version kubectl "$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)"
  check_the_latest_version helm "$(curl -s https://api.github.com/repos/kubernetes/helm/releases/latest | jq -r .tag_name)"
  check_the_latest_version terraform "$(curl -s https://api.github.com/repos/hashicorp/terraform/releases/latest | jq -r .tag_name | sed -e 's/^v//')"
  check_the_latest_version kops "$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | jq -r .tag_name)"
  echo
  echo -n 'Press enter to install components: '
  read

  install_binary kubectl "https://storage.googleapis.com/kubernetes-release/release/${versions['kubectl']}/bin/linux/amd64/kubectl"
  install_binary kops "https://github.com/kubernetes/kops/releases/download/${versions['kops']}/kops-linux-amd64"

  if [ ! -f "$BIN_DIR/helm" ]; then
    extract_tgz "https://storage.googleapis.com/kubernetes-helm/helm-${versions['helm']}-linux-amd64.tar.gz"
    mv "$TMP_DIR/helm/linux-amd64/helm" "$BIN_DIR/helm"
    chmod +x "$BIN_DIR/helm"
  else
    echo "SKIP: helm is already installed in $BIN_DIR"
  fi

  if [ ! -f "$BIN_DIR/terraform" ]; then
    extract_zip terraform "https://releases.hashicorp.com/terraform/${versions['terraform']}/terraform_${versions['terraform']}_linux_amd64.zip"
    mv "$TMP_DIR/terraform/terraform" "$BIN_DIR/terraform"
    chmod +x "$BIN_DIR/terraform"
  else
    echo "SKIP: terraform is already installed in $BIN_DIR"
  fi
}

function check_the_latest_version () {
  name="$1"
  version="$2"
  versions["$name"]="$version"
  echo "- $name $version"
}

function install_binary () {
  name="$1"
  url="$2"
  if [ ! -f "$BIN_DIR/$name" ]; then
    echo "Installing $name..."
    curl -L -o "$BIN_DIR/$name" "$url"
    chmod +x "$BIN_DIR/$name"
  else
    echo "SKIP: $name is already installed in $BIN_DIR"
  fi
}

function extract_tgz () {
  name="$1"
  url="$2"
  curl -L -o "$TMP_DIR/$name.tgz" "$url"
  rm -fr "$TMP_DIR/$name"
  tar -C "$TMP_DIR/$name" xzf "$TMP_DIR/$name.tgz"
}

function extract_zip () {
  name="$1"
  url="$2"
  curl -L -o "$TMP_DIR/$name.zip" "$url"
  rm -fr "$TMP_DIR/$name"
  unzip -d "$TMP_DIR/$name" "$TMP_DIR/$name.zip"
}

main
