#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
# Treat unset variables as an error when substituting.
set -eu

# Pipeline’s return status is the value of the last (rightmost) command to exit
# with a non-zero status, or zero if all commands exit successfully.
set -o pipefail

print_usage() {
  printf "Usage: $ ./setup.sh -a {access_key_id} -s {secret_key_id}"
  exit 1
}

# Using flags to passing input to a script
while getopts a:s: flag
do
    case "${flag}" in
      a) fAccessKeyId=${OPTARG};;
      s) fSecretAccessKey=${OPTARG};;
      *) print_usage;;
    esac
done
# [$#] is a special variable in bash, that expands to the number of arguments
if [ $# -ne 4 ]; then
  print_usage;
fi

# Timestamp
timestamp=$(date '+%Y%m%d%H%M%S')
# Define AWS S3 bucket
s3Bucket="terraform-$timestamp"
# Define AWS user name
username="Bob-$timestamp"
# Define Policy name
policyname="policy-$timestamp"
# Define Region
region=us-east-1

# Configure root AWS profile
aws configure set aws_access_key_id $fAccessKeyId --profile admin
aws configure set aws_secret_access_key $fSecretAccessKey --profile admin
aws configure set region $region --profile admin
aws configure set output json --profile admin
aws configure set cli_pager "" --profile admin
export AWS_PROFILE=admin

# Create S3 bucket
s3Location=$(aws s3api create-bucket --bucket $s3Bucket --region $region --acl private | jq -r '.Location')

# Create AWS user name
# Bash Process Substitution:: http://mywiki.wooledge.org/ProcessSubstitution
# More info: https://askubuntu.com/a/678919
read userId userArn < <(echo $(aws iam create-user --user-name $username | jq -r '.User.UserId, .User.Arn'))

# Replace bash variables and write to new policy file
policyDocument=$(cat policy.json | sed -e "s#\${s3Bucket}#${s3Bucket}#g" -e "s#\${userArn}#${userArn}#g")

# Creates a new managed policy for your AWS account.
policyArn=$(aws iam create-policy --policy-name $policyname \
  --policy-document file://<(echo $policyDocument) | jq -r '.Policy.Arn')

# Attach a new policy to AWS account.
aws iam attach-user-policy --policy-arn $policyArn --user-name $username

# Create access key ID and secret access key
read accessKeyId secretAccessKey < <(echo $(aws iam create-access-key --user-name $username | jq -r '.AccessKey.AccessKeyId, .AccessKey.SecretAccessKey'))

echo "====== Information ======
s3Location      = $s3Location
UserId          = $userId
UserArn         = $userArn
PolicyArn       = $policyArn
AccessKeyId     = $accessKeyId
SecretAccessKey = $secretAccessKey"

echo "====== AWS configure command ======
aws configure set aws_access_key_id $accessKeyId --profile terraform
aws configure set aws_secret_access_key $secretAccessKey --profile terraform
aws configure set region $region --profile terraform
aws configure set output json --profile terraform
aws configure set cli_pager '""' --profile terraform
export AWS_PROFILE=terraform"
