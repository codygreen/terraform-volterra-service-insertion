# Terraform Volterra Service Insertion

# Deploy Volterra AWS VPC Site

```bash
cd volterra-site
export VES_P12_PASSWORD=your_password
terraform init
terraform apply
```

# Deploy BIG-IPs into VPC

The BIG-IP module expects a list of strings that define the allows IP addresses for the management interface.

```bash
cd big-ip-runtime-init
terraform output -state=../volterra-site/terraform.tfstate --json > volterra-site.auto.tfvars.json
terraform init
terraform apply
```
