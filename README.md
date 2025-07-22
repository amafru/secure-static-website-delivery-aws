# Secure Static Webapp Delivery on AWS
The manifests in this repository are designed to set up a CI/CD-enabled static website delivery using mainly AWS S3, CloudFront, and GitHub Actions. 

The result of this workload is an end-to-end pipeline for secure static website deployment with automation and DNS integration.

# Prerequisites

1. Buy a domain e.g. example.com if you want one - GoDaddy, Namecheap etc

2. Create a separate s3 bucket for tfstate management e.g. my-tfstate-bucket4455 and update the terraform block within main.tf to use this backend

3. Host your domain - the one from step 1 above - in AWS Route 53. Point the Nameservers to Route53 - (Docs here: https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/AboutHZWorkingWith.html) 

4. Request a TLS certificate for HTTPS traffic from ACM. 
Docs: https://docs.aws.amazon.com/acm/latest/userguide/setup.html

*Note: Cloudfront requires certs to be issued in in us-east-1 regardless of where consuming resources are located*

5. Attach IAM policies that allow access to the S3 Buckets (tfstate and website_assets) to the AWS User used in running the GitHub Actions pipeline.

The user only needs the following permissions:

"s3:GetObject"
"s3:PutObject",
"s3:ListBucket",
"s3:DeleteObject"
"s3:GetBucketPolicy",
"s3:GetBucketAcl,
"route53:ListHostedZones",
"route53:GetHostedZone",
"acm:ListCertificates",
"acm:DescribeCertificate",
"cloudfront:GetOriginAccessControl"

These can be added via an inline policy and restricted only to the 2 necessary s3 buckets.

6. Set the Secret Access Key ID and Secret for this user in GitHub (Actions) as repository secrets.

7. Within GitHub, create any environment variables + values  that you’d like to keep out of source control, to represent variables held in the *.auto.tfvars file if you were running this locally.



*For example: You might want to keep your domain name value example.com; or your subdomain myapp.example.com out of source control*

# Deployment
- Terraform takes a long time to complete the first time this configuration is run. It takes a a little while (approx 10 mins) for the creation of the CloudFront distribution to complete.

- It can then take about 30mins for the SSL certificate config to be properly propagated and for CloudFront to respond when the site url is accessed  
