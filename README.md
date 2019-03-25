# pks-automation

#Overview
This automation installs PKS from scratch on any cloud, well, on AWS in first phase.
This is done in four stages.
First, we lay out IaaS components on your chosen cloud. We have taken AWS as the first cloud to start with.
Amazon can thank me.
Second, we download the Terraform tfstate file, and use it to populate the creds files.
These are the creds files we will use for BOSH and PKS configuration.
Third, we will configure the BOSH director using the creds populated earlier.
And last, we will configure the PKS tile using the creds populated earlier.

Check your IaaS requirements here - https://docs.pivotal.io/runtimes/pks/1-3/aws-requirements.html

#Prepare to automate PKS
1. Create a private GIT repo for secrets files required in the pipelines. For this lab we will use secret repo created here.
We have used local folder ~/workspace/pcf-automation/platform-automation-private for this repo.

2. Create pks-terraform.tfvars in your secrets (pvt) repo with details mentioned here - https://docs.pivotal.io/pivotalcf/2-4/om/aws/prepare-env-terraform.html#download Remember the Region and AZ you selected here.

3. Create bosh-director-tfstate-map.yml in your in your secrets (pvt) repo. This file is used to create secrets for BOSH director tile. Sample -

4. Create pks-tfstate-map.yml file in your in your secrets (pvt) repo. This file is used to create secrets for PKS tile. Sample -

5. Create terraform-tfstate-keys.txt in your secrets (pvt) repo. This file has keys for bosh-director-tfstate-map.yml. Sample -

6. Create pks-terraform-tfstate-keys.txt in your secrets (pvt) repo. This file has keys for pks-tfstate-map.yml. Sample -

7. cp the .sh scripts to the secrets repo folder. The script assumes files in current directory.

#Go!
1. Setup a pipeline to automate IaaS and Ops Man setup.
fly -t w sp -p terraforming-pks-on-aws \
--config aws/pipeline-terraforming-pks-aws.yml \
--load-vars-from ~/workspace/pcf-automation/platform-automation-private/creds-terraforming-aws.yml \
--var "git_private_key=$(cat ~/.ssh/id_rsa)"

fly -t w up -p terraforming-pks-on-aws

2. Navigate to your Concourse UI and kick star terraforming-pks-on-aws/setup-aws-install-opsman job.

3. Upon successful completion of the pipeline you need to setup Ops Man username and password. For the purpose of this demo we will use admin/admin. If you use something else then you need to change the values in the secrets YAMLs.

4. Use `aws configure` to login to aws

5. Go to the secrets repo folder and run state-to-creds.sh

6. Setup a pipeline to setup BOSH director

fly -t w sp -p aws-config-director \
--config aws/pipeline-config-p-bosh.yml \
--load-vars-from ~/workspace/pcf-automation/platform-automation-private/creds-aws-p-bosh.yml \
--var "git_private_key=$(cat ~/.ssh/id_rsa)"

fly -t w up -p aws-config-director

7. Navigate to your Concourse UI and start the aws-config-director/configure-p-bosh job.

8. Setup a pipeline to stage and configure PKS tile

fly -t w sp -p aws-stage-config-pks \
--config aws/pipeline-stage-config-pks.yml \
--load-vars-from ~/workspace/pcf-automation/platform-automation-private/creds-aws-pivotal-container-service.yml \
--var "git_private_key=$(cat ~/.ssh/id_rsa)"

fly -t w up -p aws-stage-config-pks
