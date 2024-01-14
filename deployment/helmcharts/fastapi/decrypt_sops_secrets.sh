#!/bin/bash

#secrets_path=secrets
#config_path=config
#temporary_name=secret.decrypted.json
#decrypted_file_name=secret.service.account.key.decrypted.json
secrets_path=secrets/$ENVIRONMENT
ARN=arn:aws:kms:eu-central-1:209591221760:key/6c7d633f-e5b0-4c88-a72a-ee864caeb5f3

# Loop for decrypt service account key and format like passowrd for docker pull secret "_helper.tpl"
#decrypt_service_account_key () {
#    for file in $secrets_path/*; do
#        sops -d $file > $secrets_path/$decrypted_file_name.temporary
#        jq -c . $secrets_path/$decrypted_file_name.temporary > $secrets_path/$decrypted_file_name.temporary2
#        perl -pe 's/"/\\"/g' $secrets_path/$decrypted_file_name.temporary2 > $secrets_path/$decrypted_file_name.temporary3
#        perl -pe 's/\\n/\\\\n/g' $secrets_path/$decrypted_file_name.temporary3 > $secrets_path/$decrypted_file_name.temporary4
#        cat $secrets_path/$decrypted_file_name.temporary4 | tr -d "[:space:]" > $secrets_path/$decrypted_file_name
#        rm -f $secrets_path/$decrypted_file_name.*
#    done
#}

# Loop for decrypt secrets in config folder
decrypt_envfile_secrets () {
    for folder in $secrets_path; do
#        if [[ -f $folder/secrets.yaml ]]
#        then
            sops -d --kms $ARN $folder/secrets.yaml > $folder/secrets.decrypted.yaml
#            sops -d $folder/google-application-credentials.json > $folder/google-application-credentials.decrypted.json
#        fi
    done
}

#decrypt_service_account_key
decrypt_envfile_secrets
