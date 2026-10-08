#!/bin/bash
set -e

export AWS_REGION="us-east-1"
export AWS_DEFAULT_REGION="us-east-1"

DOMAIN="study.adriandrummond.com"
LOGIN_DOMAIN="login.adriandrummond.com"
CALLBACK_URL="https://${DOMAIN}/callback"
LOGOUT_URL="https://adriandrummond.wordpress.com"

echo "=========================================="
echo " Provisioning Amazon Cognito for $DOMAIN  "
echo "=========================================="

# 1. Use existing validated ACM Certificate in us-east-1
CERT_ARN="arn:aws:acm:us-east-1:101845606311:certificate/cdbd1ce4-f5c5-4fa7-af79-7c90be7c4301"
echo "Using validated ACM Certificate ARN: $CERT_ARN"

# 2. Create User Pool
echo "Creating User Pool..."
POOL_ID=$(aws cognito-idp create-user-pool \
    --pool-name "study-server-pool" \
    --auto-verified-attributes email \
    --username-attributes email \
    --policies 'PasswordPolicy={MinimumLength=8,RequireUppercase=true,RequireLowercase=true,RequireNumbers=true,RequireSymbols=true}' \
    --query 'UserPool.Id' --output text)
echo "User Pool ID: $POOL_ID"

# 3. Create App Client
echo "Creating App Client..."
CLIENT_ID=$(aws cognito-idp create-user-pool-client \
    --user-pool-id "$POOL_ID" \
    --client-name "study-server-app" \
    --generate-secret \
    --allowed-o-auth-flows code \
    --allowed-o-auth-scopes email openid profile \
    --callback-urls "$CALLBACK_URL" \
    --logout-urls "$LOGOUT_URL" \
    --supported-identity-providers COGNITO \
    --allowed-o-auth-flows-user-pool-client \
    --query 'UserPoolClient.ClientId' --output text)

CLIENT_SECRET=$(aws cognito-idp describe-user-pool-client --user-pool-id "$POOL_ID" --client-id "$CLIENT_ID" --query 'UserPoolClient.ClientSecret' --output text)
echo "App Client ID: $CLIENT_ID"

# 4. Create Identity Pool
echo "Creating Identity Pool..."
IDENTITY_POOL_ID=$(aws cognito-identity create-identity-pool \
    --identity-pool-name "study_server_identity_pool" \
    --allow-unauthenticated-identities \
    --cognito-identity-providers ProviderName="cognito-idp.us-east-1.amazonaws.com/${POOL_ID}",ClientId="${CLIENT_ID}" \
    --query 'IdentityPoolId' --output text)
echo "Identity Pool ID: $IDENTITY_POOL_ID"

# 5. Create Custom Domain
echo "Creating Custom Domain $LOGIN_DOMAIN for User Pool using validated certificate..."
DOMAIN_OUTPUT=$(aws cognito-idp create-user-pool-domain \
    --domain "$LOGIN_DOMAIN" \
    --user-pool-id "$POOL_ID" \
    --custom-domain-config CertificateArn="$CERT_ARN" \
    --query 'CloudFrontDistribution' --output text) || echo "Domain creation failed."

echo "=========================================="
echo " 🚨 ALMOST DONE! FINAL DNS STEP 🚨 "
echo "=========================================="
echo "Cognito has created a CloudFront distribution for your domain."
echo "Please add the following CNAME record to your DNS:"
echo "Name: login.adriandrummond.com"
echo "Value: $DOMAIN_OUTPUT"
echo "=========================================="

echo "=========================================="
echo " Cognito Provisioning Complete!           "
echo " Please add these to your .env file:      "
echo "=========================================="
echo "COGNITO_USER_POOL_ID=\"$POOL_ID\""
echo "COGNITO_CLIENT_ID=\"$CLIENT_ID\""
echo "COGNITO_CLIENT_SECRET=\"$CLIENT_SECRET\""
echo "COGNITO_DOMAIN=\"$LOGIN_DOMAIN\""
echo "COGNITO_IDENTITY_POOL_ID=\"$IDENTITY_POOL_ID\""
echo "=========================================="
