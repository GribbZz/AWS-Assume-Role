#!/bin/bash

set -euo pipefail

# Cleanup function to remove all profiles except 'default'
cleanup_profiles() {
  CRED_FILE="$HOME/.aws/credentials"
  TMP_FILE=$(mktemp)

  echo "⚠️ Cleaning non-default profiles from $CRED_FILE..."

  # Keep only the 'default' profile, and remove all other profiles
  awk '
    BEGIN { keep = 1 }
    /^\[default\]/ { keep = 1 }
    /^\[.*\]/ {
      if ($0 ~ /^\[default\]/) {
        keep = 1
      } else {
        keep = 0
      }
    }
    {
      if (keep) print
    }
  ' "$CRED_FILE" > "$TMP_FILE"

  mv "$TMP_FILE" "$CRED_FILE"
  echo "✅ Cleanup complete: All profiles except 'default' removed."
}

# Ask the user if they want to perform a cleanup
read -p "Do you want to clean up non-default profiles from ~/.aws/credentials? (y/N): " CLEANUP_CHOICE
CLEANUP_CHOICE=${CLEANUP_CHOICE:-N}

if [[ "$CLEANUP_CHOICE" == "y" || "$CLEANUP_CHOICE" == "Y" ]]; then
  cleanup_profiles
fi

# Prompt for source AWS CLI profile and role details
read -p "Enter source AWS CLI profile (leave blank to use 'default'): " PROFILE
PROFILE=${PROFILE:-default}

read -p "Enter ROLE ARN (e.g., arn:aws:iam::123456789012:role/MyRole): " ROLE_ARN
read -p "Enter MFA ARN (e.g., arn:aws:iam::123456789012:mfa/your.mfa.name): " MFA_ARN
read -p "Enter MFA token code: " TOKEN_CODE

# Assume the role using AWS STS
CREDS=$(aws sts assume-role \
  --profile "$PROFILE" \
  --role-arn "$ROLE_ARN" \
  --role-session-name session \
  --duration-seconds 3600 \
  --serial-number "$MFA_ARN" \
  --token-code "$TOKEN_CODE")

# Extract temporary credentials from the JSON response
AWS_ACCESS_KEY_ID=$(jq -r '.Credentials.AccessKeyId' <<< "$CREDS")
AWS_SECRET_ACCESS_KEY=$(jq -r '.Credentials.SecretAccessKey' <<< "$CREDS")
AWS_SESSION_TOKEN=$(jq -r '.Credentials.SessionToken' <<< "$CREDS")
EXPIRATION=$(jq -r '.Credentials.Expiration' <<< "$CREDS")

# Prompt for destination profile to save credentials
read -p "Enter name for the profile to store credentials (e.g., temp-role): " TARGET_PROFILE

# Use `aws configure` to set the credentials for the given profile
aws configure set aws_access_key_id "$AWS_ACCESS_KEY_ID" --profile "$TARGET_PROFILE"
aws configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY" --profile "$TARGET_PROFILE"
aws configure set aws_session_token "$AWS_SESSION_TOKEN" --profile "$TARGET_PROFILE"

echo -e "\n✅ Assume role credentials saved under profile: [$TARGET_PROFILE]"
echo "   Expiration: $EXPIRATION"
echo "   To use it:  run each command/tool with the --profile parameter, e.g. aws s3 ls --profile $TARGET_PROFILE"
