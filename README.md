# Overview
This automation installs PKS from scratch on any cloud, well, on AWS in first phase.
This is done in four stages.

First, we lay out IaaS components on your chosen cloud. We have taken AWS as the first cloud to start with.

Second, we download the Terraform tfstate file, and use it to populate the creds files.
These are the creds files we will use for BOSH and PKS configuration.

Third, we will configure the BOSH director using the creds populated earlier.

And last, we will configure the PKS tile using the creds populated earlier.

Check your IaaS requirements here - https://docs.pivotal.io/runtimes/pks/1-3/aws-requirements.html

# Prepare to automate PKS
1. Git clone this repo -
`git clone https://github.com/msathe-tech/pks-automation.git`
We have used local folder `~/workspace/pcf-automation/pks-automation` for this repo.

2. Create a private GIT repo for secrets files required in the pipelines. For this lab we will use secret repo created here.
We have used local folder `~/workspace/pcf-automation/platform-automation-private` for this repo.
To keep things simple, keep the private repo and pks-automation repo in the same folder, e.g. `~/workspace/pcf-automation`

3. Create pks-terraform.tfvars in your secrets (pvt) repo with details mentioned here - https://docs.pivotal.io/pivotalcf/2-4/om/aws/prepare-env-terraform.html#download Remember the Region and AZ you selected here. This file is used as input for the terraform script. Sample here - https://github.com/msathe-tech/pks-automation/blob/master/credentials/pks-terraform.tfvars

4. Create creds-terraforming-aws.yml in your secrets (pvt) repo. Sample - https://github.com/msathe-tech/pks-automation/blob/master/credentials/creds-terraforming-aws.yml

5. Create bosh-director-tfstate-map.yml in your in your secrets (pvt) repo. This file is used to create secrets for BOSH director tile. Sample - https://github.com/msathe-tech/pks-automation/blob/master/credentials/bosh-director-tfstate-map.yml

6. Create pks-tfstate-map.yml file in your in your secrets (pvt) repo. This file is used to create secrets for PKS tile. Sample - https://github.com/msathe-tech/pks-automation/blob/master/credentials/pks-tfstate-map.yml

7. Create terraform-tfstate-keys.txt in your secrets (pvt) repo. This file has keys for bosh-director-tfstate-map.yml. Sample - https://github.com/msathe-tech/pks-automation/blob/master/credentials/terraform-tfstate-keys.txt

8. Create pks-terraform-tfstate-keys.txt in your secrets (pvt) repo. This file has keys for pks-tfstate-map.yml. Sample - https://github.com/msathe-tech/pks-automation/blob/master/credentials/pks-terraform-tfstate-keys.txt

9. Copy the .sh scripts from pks-automation folder to the secrets repo folder. These scripts extract values from the tfstate file of the Terraform execution and populate the YAMLs for the BOSH director and PKS tiles. The script assumes all files in current directory so it is important that you copy the the scripts in the secrets (pvt) repo folder.

# Go!

1. cd `~/workspace/pcf-automation/pks-automation`, or whatever the location of `pks-automation` repo on your machine.

2. Setup a pipeline to automate IaaS and Ops Man setup. Open `aws/pipeline-terraforming-pks-aws.yml` and change the GIT URL in the `credentials` resource to use your private git repo.
    `fly -t w sp -p terraforming-pks-on-aws \
    --config aws/pipeline-terraforming-pks-aws.yml \
    --load-vars-from ~/workspace/pcf-automation/platform-automation-private/creds-terraforming-aws.yml \
    --var "git_private_key=$(cat ~/.ssh/id_rsa)"`

    `fly -t w up -p terraforming-pks-on-aws`

3. Navigate to your Concourse UI and kick star `terraforming-pks-on-aws/setup-aws-install-opsman` job.

4. Upon successful completion of the pipeline you need to setup Ops Man username and password. For the purpose of this demo we will use admin/admin. If you use something else then you need to change the values in the secrets YAMLs.

5. Use `aws configure` to login to aws

6. Go to the secrets repo folder, run `chmod +x *.sh` and then execute `state-to-creds.sh`.

7. Setup a pipeline to setup BOSH director. Open `pipeline-config-p-bosh.yml` and change the GIT URL in the `credentials` resource to use your private git repo.

    `fly -t w sp -p aws-config-director \
    --config pipeline-config-p-bosh.yml \
    --load-vars-from ~/workspace/pcf-automation/platform-automation-private/creds-aws-p-bosh.yml \
    --var "git_private_key=$(cat ~/.ssh/id_rsa)"`

    `fly -t w up -p aws-config-director`

8. Navigate to your Concourse UI and start the `aws-config-director/configure-p-bosh` job.

9. Setup a pipeline to stage and configure PKS tile. Open `pipeline-stage-config-pks.yml` and change the GIT URL in the `credentials` resource to use your private git repo.

    `fly -t w sp -p aws-stage-config-pks \
    --config pipeline-stage-config-pks.yml \
    --load-vars-from ~/workspace/pcf-automation/platform-automation-private/creds-aws-pivotal-container-service.yml \
    --var "git_private_key=$(cat ~/.ssh/id_rsa)"`

    `fly -t w up -p aws-stage-config-pks`

10. Navigate to your Concourse UI and start the `aws-stage-config-pks/stage-pivotal-container-service` job

Note - we have kept Step 6 and 8 as separate pipelines to keep it simple and easy to understand and troubleshoot if needed. Ideally, these will be in a same pipeline as two different tasks.
