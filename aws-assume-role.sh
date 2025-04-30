#!/bin/bash

set -euo pipefail

read -p "Enter source AWS CLI profile (leave blank to use 'default'): " PROFILE
PROFILE=${PROFILE:-default}

read -p "Enter ROLE ARN (e.g., arn:aws:iam::123456789012:role/MyRole): " ROLE_ARN
read -p "Enter MFA ARN (e.g., arn:aws:iam::123456789012:mfa/your.mfa.name): " MFA_ARN
read -p "Enter MFA token code: " TOKEN_CODE

# Assume the role
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
EXPIRATION=$(jq -r '.Credentials.Expiration' <<< "$CREDS")

# Prompt for destination profile
read -p "Enter name for the profile to store credentials (e.g., temp-role): " TARGET_PROFILE

# Check if profile already exists in ~/.aws/credentials
if grep -q "^\[$TARGET_PROFILE\]" ~/.aws/credentials 2>/dev/null; then
  read -p "Profile [$TARGET_PROFILE] already exists. Overwrite? (y/N): " CONFIRM
  if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    echo "Aborted."
    exit 1
  fi
fi

# Save credentials using AWS CLI (safe method)
aws configure set profile "$TARGET_PROFILE" aws_access_key_id "$AWS_ACCESS_KEY_ID"
aws configure set profile "$TARGET_PROFILE" aws_secret_access_key "$AWS_SECRET_ACCESS_KEY"
aws configure set profile "$TARGET_PROFILE" aws_session_token "$AWS_SESSION_TOKEN"

echo -e "\n Temporary credentials saved under profile: [$TARGET_PROFILE]"
echo "   Expiration: $EXPIRATION"
echo "   To use it:  AWS_PROFILE=$TARGET_PROFILE aws s3 ls"
