#!/bin/bash

set -euo pipefail

# Check if script is being sourced
(return 0 2>/dev/null) || {
  echo "⚠️  Please run this script with:"
  echo ""
  echo "    source $0"
  echo ""
  echo "This is required to export credentials into your current shell."
  exit 1
}

read -p "Enter source AWS CLI profile (leave blank to use 'default'): " PROFILE
PROFILE=${PROFILE:-default}

read -p "Enter ROLE ARN (e.g., arn:aws:iam::123456789012:role/MyRole): " ROLE_ARN
read -p "Enter MFA ARN (e.g., arn:aws:iam::123456789012:mfa/your.mfa.name): " MFA_ARN

read -p "Enter MFA token code: " TOKEN_CODE

CREDS=$(aws sts assume-role \
  --profile "$PROFILE" \
  --role-arn "$ROLE_ARN" \
  --role-session-name session \
  --duration-seconds 3600 \
  --serial-number "$MFA_ARN" \
  --token-code "$TOKEN_CODE")

AWS_ACCESS_KEY_ID=$(jq -r '.Credentials.AccessKeyId' <<< "$CREDS")
AWS_SECRET_ACCESS_KEY=$(jq -r '.Credentials.SecretAccessKey' <<< "$CREDS")
AWS_SESSION_TOKEN=$(jq -r '.Credentials.SessionToken' <<< "$CREDS")

# Output export statements to affect parent shell
export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY
export AWS_SESSION_TOKEN

echo -e "\n✅ AWS credentials assumed and exported:"
echo "AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID"
echo "AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY"
echo "AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN"
