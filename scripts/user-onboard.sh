#!/bin/bash
set -euo pipefail

KC_URL="https://auth.home.eluusive.com"
REALM="homelab"

source ~/homelab/scripts/.env   

USERNAME="$1"
EMAIL="$2"
GROUP="${3:-players}"

TOKEN=$(curl -s -X POST "$KC_URL/realms/master/protocol/openid-connect/token" \
  -d "username=$ADMIN_USER" -d "password=$ADMIN_PASS" \
  -d "grant_type=password" -d "client_id=admin-cli" | jq -r .access_token)

USER_ID=$(curl -s -X POST "$KC_URL/admin/realms/$REALM/users" \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d "{\"username\":\"$USERNAME\",\"email\":\"$EMAIL\",\"enabled\":true,\"requiredActions\":[\"UPDATE_PASSWORD\"]}" \
  -D - | grep -i location | sed 's#.*/##' | tr -d '\r')

GROUP_ID=$(curl -s "$KC_URL/admin/realms/$REALM/groups" \
  -H "Authorization: Bearer $TOKEN" | jq -r ".[] | select(.name==\"$GROUP\") | .id")

curl -s -X PUT "$KC_URL/admin/realms/$REALM/users/$USER_ID/groups/$GROUP_ID" \
  -H "Authorization: Bearer $TOKEN"

TEMP_PASS=$(openssl rand -base64 12)
curl -s -X PUT "$KC_URL/admin/realms/$REALM/users/$USER_ID/reset-password" \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d "{\"type\":\"password\",\"value\":\"$TEMP_PASS\",\"temporary\":true}"

echo "Created $USERNAME in group $GROUP"
echo "Temporary password: $TEMP_PASS"
echo "Send Temporary password to user, along with onboarding instructions. They'll be forced to change it on first login."
