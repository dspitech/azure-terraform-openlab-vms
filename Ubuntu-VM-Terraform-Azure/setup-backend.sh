#!/usr/bin/env bash
# ============================================================
# setup-backend.sh — OPTIONNEL
# Crée le Storage Account du state Terraform et génère backend.tf
# À lancer une seule fois, avant "terraform init".
# ============================================================
set -euo pipefail

RG_NAME="${TFSTATE_RG:-OpenLab-TFState-RG}"
LOCATION="${TFSTATE_LOCATION:-swedencentral}"
CONTAINER="tfstate"
KEY="openlab-ubuntu.terraform.tfstate"

if [[ -f backend.tf ]]; then
  echo "backend.tf existe déjà : rien à faire." >&2
  exit 0
fi

# Réutilise un Storage Account existant du RG, sinon en crée un
az group create --name "$RG_NAME" --location "$LOCATION" --output none
SA="$(az storage account list -g "$RG_NAME" --query "[?starts_with(name,'tfstate')].name | [0]" -o tsv)"

if [[ -z "$SA" ]]; then
  SA="tfstate$(openssl rand -hex 6)"
  echo "==> Création du Storage Account $SA"
  az storage account create \
    --name "$SA" --resource-group "$RG_NAME" --location "$LOCATION" \
    --sku Standard_LRS --kind StorageV2 --min-tls-version TLS1_2 \
    --allow-blob-public-access false --output none
else
  echo "==> Réutilisation du Storage Account $SA"
fi

az storage container create --name "$CONTAINER" --account-name "$SA" --auth-mode key --output none

cat > backend.tf <<EOF
terraform {
  backend "azurerm" {
    resource_group_name  = "$RG_NAME"
    storage_account_name = "$SA"
    container_name       = "$CONTAINER"
    key                  = "$KEY"
  }
}
EOF

echo "==> backend.tf généré. Lancez maintenant : terraform init"
