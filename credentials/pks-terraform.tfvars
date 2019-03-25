env_name           = "env name of your choice (used for subdomain name and other IaaS components)"
access_key         = "Your AWS access key"
secret_key         = "Your AWS secret key"
region             = "us-east-1" or your AWS region
availability_zones = ["us-east-1b"] or your AWS AZ
ops_manager_ami    = "ami-0e808a8943bccb9dc" or the AMI for the region you selected
rds_instance_count = 0
dns_suffix         = "your base domain"
vpc_cidr           = "10.0.0.0/16"

ssl_cert = <<EOF
-----BEGIN CERTIFICATE-----
YOUR...CERT
-----END CERTIFICATE-----
EOF

ssl_private_key = <<EOF
-----BEGIN PRIVATE KEY-----
YOUR...PVT...KEY
-----END PRIVATE KEY-----
EOF

tags = {
    Team = "Your team tag"
    Project = "Your project tag"
}
