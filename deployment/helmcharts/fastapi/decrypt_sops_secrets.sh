#!/bin/bash

secrets_path=secrets/$ENVIRONMENT
#ARN=arn:aws:kms:eu-central-1:209591221760:key/6c7d633f-e5b0-4c88-a72a-ee864caeb5f3

# Loop for decrypt secrets in config folder
decrypt_envfile_secrets () {
    for folder in $secrets_path; do
#            sops -d --kms $ARN $folder/secrets_backup_aws.yaml > $folder/secrets_backup_gcp.yaml
            sops -d $folder/secrets.yaml > $folder/secrets.decrypted.yaml
    done
}

decrypt_envfile_secrets
