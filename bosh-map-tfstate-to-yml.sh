cp bosh-director-tfstate-map.yml creds-aws-p-bosh.yml

while read -r key; do
  value=$(terraform output $key)
  echo ${value}
  sed -i "" "s!: ${key}!: ${value}!g" creds-aws-p-bosh.yml
done < terraform-tfstate-keys.txt

terraform output ops_manager_ssh_private_key | perl -pe 's/\s+/\n/g' | \
sed -e '1,4d' |sed -e '$d' | sed -e '$d' | sed -e '$d' | sed -e '$d' | \
sed -e '$d' | perl -pe 's/\s+/\n/g' | sed '1 i\
-----BEGIN RSA PRIVATE KEY-----' | perl -pe 's/-----BEGIN RSA PRIVATE KEY-----/-----BEGIN RSA PRIVATE KEY-----\n/g' | \
perl -pe 's/^/    /g' >> creds-aws-p-bosh.yml

end_key="-----END RSA PRIVATE KEY-----"
echo $end_key | perl -pe 's/${end_key}/    ${end_key}/' >> creds-aws-p-bosh.yml
