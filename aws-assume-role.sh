#!/bin/bash

set -euo pipefail

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

export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY
export AWS_SESSION_TOKEN

echo -e "\n✅ AWS credentials assumed and exported:"
echo "AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID"
echo "AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY"
echo "AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN"

echo -e "\n⚠️ For scoutsuite use the following one liner:"
echo "export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID; export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY; AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN"
