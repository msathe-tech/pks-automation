echo "Enter ENV_NAME (env_name in tfvars file) [default=pvtl]: "
read ENV_NAME
ENV_NAME=${ENV_NAME:-pvtl}

echo "Enter S3_BUCKET (bucket: terraform task in terraform pipeline yml) [default=platform-automation-terraform]: "
read S3_BUCKET
S3_BUCKET=${S3_BUCKET:-platform-automation-terraform}

echo "Enter S3_BUCKET_KEY (key: terraform task in terraform pipeline yml) [default=pks-on-aws/terraform.tfstate]: "
read S3_BUCKET_KEY
S3_BUCKET_KEY=${S3_BUCKET_KEY:-pks-on-aws/terraform.tfstate}

echo "Downloading terraform.tfstate"
aws s3api get-object --bucket ${S3_BUCKET} --key env:/${ENV_NAME}/${S3_BUCKET_KEY} terraform.tfstate

echo "Mapping tfstate to BOSH creds yml"
./bosh-map-tfstate-to-yml.sh

echo "Mapping tfstate to PKS creds yml"
./pks-map-tvstate-to-yml.sh

git add .
git commit -m "change" -n
git push
