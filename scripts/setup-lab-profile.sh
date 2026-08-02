#!/usr/bin/env bash
# Scaffolds a [lab] profile for each cloud CLI, interactively and idempotently.
# Run on the HOST, not in the container. Credentials never enter this repo;
# the container sees them only through read-only bind-mounts.
set -euo pipefail

bold() { printf '\033[1m%s\033[0m\n' "$*"; }

ask() {
  local reply
  read -r -p "$1 [y/N] " reply
  [[ "$reply" == "y" || "$reply" == "Y" ]]
}

bold "hedronite-devops-lab — [lab] cloud profile scaffold"
echo

# ---------- AWS ----------
if ask "Set up an AWS [lab] profile?"; then
  if ! command -v aws >/dev/null 2>&1; then
    echo "aws CLI not found; install it first (brew install awscli), then re-run."
  elif grep -qs '^\[lab\]' "${HOME}/.aws/credentials" 2>/dev/null; then
    echo "[lab] profile already present in ~/.aws/credentials; skipping."
  else
    echo "Create a dedicated IAM user (or role) for lab work and attach a"
    echo "scoped policy, not AdministratorAccess. Reference:"
    echo "  https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html"
    echo "Enter that user's access key when prompted."
    aws configure --profile lab
    echo "AWS [lab] profile written. In the container: AWS_PROFILE=lab aws sts get-caller-identity"
  fi
  echo
fi

# ---------- GCP ----------
if ask "Set up a GCP lab configuration?"; then
  if ! command -v gcloud >/dev/null 2>&1; then
    echo "gcloud not found; install the Google Cloud SDK first, then re-run."
  else
    if gcloud config configurations list --format='value(name)' 2>/dev/null | grep -qx 'lab'; then
      echo "gcloud configuration 'lab' already exists; skipping creation."
    else
      read -r -p "Lab project id (e.g. hedronite-lab): " gcp_project
      gcloud config configurations create lab
      gcloud config set project "$gcp_project"
    fi
    if ask "Run application-default login now (opens a browser)?"; then
      gcloud auth application-default login
    fi
    echo "In the container: gcloud config configurations activate lab"
  fi
  echo
fi

# ---------- Azure ----------
if ask "Set up an Azure lab service principal?"; then
  if ! command -v az >/dev/null 2>&1; then
    echo "az not found; install the Azure CLI first, then re-run."
  else
    if ! az account show >/dev/null 2>&1; then
      az login
    fi
    if az ad sp list --display-name hedronite-lab --query '[0].appId' -o tsv 2>/dev/null | grep -q .; then
      echo "Service principal 'hedronite-lab' already exists; skipping creation."
    else
      sub_id="$(az account show --query id -o tsv)"
      read -r -p "Scope the SP to subscription ${sub_id}? Enter a narrower scope or press enter to accept: " scope
      scope="${scope:-/subscriptions/${sub_id}}"
      echo "Creating SP 'hedronite-lab' with Contributor on ${scope}."
      echo "Store the returned secret in your password manager; it is shown once."
      az ad sp create-for-rbac --name hedronite-lab --role Contributor --scopes "$scope"
    fi
    echo "In the container: az login --service-principal (or mount ~/.azure after az login here)"
  fi
  echo
fi

bold "Done. The lab() function mounts ~/.aws, ~/.config/gcloud, ~/.azure read-only."
