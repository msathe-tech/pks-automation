#Configure BOSH director on AWS

Prereqs -
Ops Man is already set on aws

fly -t w sp -p aws-config-director \
--config aws/pipeline-config-p-bosh.yml \
--load-vars-from ~/workspace/pcf-automation/platform-automation-private/creds-aws-p-bosh.yml \
--var "git_private_key=$(cat ~/.ssh/id_rsa)"
