# Overview
This automation installs PKS from scratch on any cloud, well, on AWS in first phase.
This is done in four stages.

* First, we lay out IaaS components on your chosen cloud. We have taken AWS as the first cloud to start with.
* Second, we download the Terraform tfstate file, and use it to populate the creds files.
These are the creds files we will use for BOSH and PKS configuration.
* Third, we will configure the BOSH director using the creds populated earlier.
* And last, we will configure the PKS tile using the creds populated earlier.

>Note - we have kept third and fourth step as separate pipelines to keep it easy to understand and troubleshoot if needed. Ideally, these will be in a same pipeline as two different tasks.

Check your IaaS requirements [here](https://docs.pivotal.io/runtimes/pks/1-3/aws-requirements.html)

# Prepare to automate PKS
1. Create a S3 bucket on AWS. For simplicity create it in `us-east-1` region.

2. We have used local folder `~/workspace/pcf-automation/pks-automation` for this repo. Run
    * `mkdir -p ~/workspace/pcf-automation`
    * `cd ~/workspace/pcf-automation`
    * `git clone https://github.com/msathe-tech/pks-automation.git`

3. Create a private GIT repo with local folder `~/workspace/pcf-automation/platform-automation-private`.
To keep things simple, keep the `platform-automation-private` and `pks-automation` repo in the same folder, i.e. `~/workspace/pcf-automation`. Add following files to `platform-automation-private` and git push them.
    * `pks-terraform.tfvars` with details mentioned [here](https://docs.pivotal.io/pivotalcf/2-4/om/aws/prepare-env-terraform.html#download) Remember the Region and AZ you selected here. [Sample](https://github.com/msathe-tech/pks-automation/blob/master/credentials/pks-terraform.tfvars)
    * `creds-terraforming-aws.yml` [Sample](https://github.com/msathe-tech/pks-automation/blob/master/credentials/creds-terraforming-aws.yml). Change `bucket` value to the bucket name you created in Step #1.
    * `bosh-director-tfstate-map.yml` used to create secrets for BOSH director tile. [Sample](https://github.com/msathe-tech/pks-automation/blob/master/credentials/bosh-director-tfstate-map.yml). Revisit this file and change __opsman_userid__ and __opsman_password__ values after you've setup Ops Man.
    * `pks-tfstate-map.yml` used to create secrets for PKS tile. [Sample](https://github.com/msathe-tech/pks-automation/blob/master/credentials/pks-tfstate-map.yml). Revisit this file and change __opsman_userid__ and __opsman_password__ values after you've setup Ops Man.
    * `terraform-tfstate-keys.txt` has keys for bosh-director-tfstate-map.yml. [Sample](https://github.com/msathe-tech/pks-automation/blob/master/credentials/terraform-tfstate-keys.txt)
    * `pks-terraform-tfstate-keys.txt` has keys for pks-tfstate-map.yml. [Sample](https://github.com/msathe-tech/pks-automation/blob/master/credentials/pks-terraform-tfstate-keys.txt)

4. Copy the .sh scripts from `pks-automation` folder to `platform-automation-private`. These scripts extract values from the tfstate file of the Terraform execution and populate the YAMLs for the BOSH director and PKS tiles. The script assumes all files in current directory so it is important that you copy the the scripts in `platform-automation-private`.

# Go!

1. `cd ~/workspace/pcf-automation/pks-automation`

2. Setup a pipeline to automate IaaS and Ops Man setup.
    * Open `pipeline-terraforming-pks-aws.yml` and change the GIT URL in the `credentials` resource to use your private git repo.
    * `fly -t w sp -p terraforming-pks-on-aws \
    --config pipeline-terraforming-pks-aws.yml \
    --load-vars-from ~/workspace/pcf-automation/platform-automation-private/creds-terraforming-aws.yml \
    --var "git_private_key=$(cat ~/.ssh/id_rsa)"`
    * `fly -t w up -p terraforming-pks-on-aws`

3. Navigate to your Concourse UI and kick star `terraforming-pks-on-aws/setup-aws-install-opsman` job.

4. Take a pause here, and pat yourself on the back. Because, you just setup IaaS and OpsMan using full automation. For the purpose of this lab we are using Route53 as DNS. So go ahead and ensure that the Route53 has the new domain created.

5. Open the terraform.tfstate file from the S3 bucket and search for `env_dns_zone_name_servers`. Add NS record in the base domain for <env_name>/your_base_domain with entries in `env_dns_zone_name_servers`. Note the public IP from A-record entry for *pcf.<env_name>/your_base_domain*. Give it some time and then run `nslookup pcf.<env_name>/your_base_domain`, ensure that the name resolves to the public IP address you noted earlier.

6. Configure Ops Man user
    * Access `https://pcf.<env_name>/your_base_domain`
    * Select *Internal Authentication*
    * For the purpose of this demo we will use __*admin/admin*__ for Ops Man user. If you use something else then you need to change the values in the secrets YAMLs.
    * Set passphrase as __*passphrase*__
    * Create user. This will create a new UAA user called __*admin*__ with password __*admin*__
    * Ensure you can login to Ops Man using __*admin/admin*__

6. Run `aws configure` to login to aws

7. Run
    * `cd ~/workspace/pcf-automation/platform-automation-private`
    * `chmod +x *.sh`
    * `./state-to-creds.sh` - make sure you enter correct S3 bucket name and key

8. Setup a pipeline to setup BOSH director.
    * Open `pipeline-config-p-bosh.yml` and change the GIT URL in the `credentials` resource to use your private git repo.
    * `fly -t w sp -p aws-config-director \
    --config pipeline-config-p-bosh.yml \
    --load-vars-from ~/workspace/pcf-automation/platform-automation-private/creds-aws-p-bosh.yml \
    --var "git_private_key=$(cat ~/.ssh/id_rsa)"`
    * `fly -t w up -p aws-config-director`

9. Navigate to your Concourse UI and start the `aws-config-director/configure-p-bosh` job.

10. Setup a pipeline to stage and configure PKS tile.
    * Open `pipeline-stage-config-pks.yml` and change the GIT URL in the `credentials` resource to use your private git repo.
    * `fly -t w sp -p aws-stage-config-pks \
    --config pipeline-stage-config-pks.yml \
    --load-vars-from ~/workspace/pcf-automation/platform-automation-private/creds-aws-pivotal-container-service.yml \
    --var "git_private_key=$(cat ~/.ssh/id_rsa)"`
    * `fly -t w up -p aws-stage-config-pks`

11. Navigate to your Concourse UI and start the `aws-stage-config-pks/stage-pivotal-container-service` job
    * You might notice error similar to following - `could not execute "download-product": could not download stemcell: could not download product file stemcells-ubuntu-xenial 170.15: user with email 'ABC@pivotal.io' has not accepted the current EULA for release with 'id'=264505. The EULA for this release can be accepted at https://network.pivotal.io/products/233/releases/264505/eulas/120`
    * If you see error like the one above you just need to accept the EULA using the URL given in the error. You will need to login to pivnet for the same
    * Once that is done you can go back and run the pipeline job again
