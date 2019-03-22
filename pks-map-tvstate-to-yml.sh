cp pks-tfstate-map.yml creds-aws-pivotal-container-service.yml

while read -r key; do
  value=$(terraform output $key)
  echo ${value}
  sed -i "" "s!: ${key}!: ${value}!g" creds-aws-pivotal-container-service.yml
done < pks-terraform-tfstate-keys.txt

value=$(terraform output azs)
echo ${value}
sed -i "" "s!azs!${value}!g" creds-aws-pivotal-container-service.yml

pks_api=$(terraform output pks_api_endpoint)
mkcert ${pks_api}
cat ${pks_api}.pem | \
perl -pe 's/^/    /g' >> creds-aws-pivotal-container-service.yml

echo -e "\npivotal-container-service/pks_tls/privatekey: |" >> creds-aws-pivotal-container-service.yml
cat ${pks_api}-key.pem | \
perl -pe 's/^/    /g' >> creds-aws-pivotal-container-service.yml
