# terraform-volterra-service-insertion

# Deploy Volterra AWS VPC Site

```bash
cd volterra-site
export VES_P12_PASSWORD=your_password
terraform init
terraform apply
```

# Deploy BIG-IPs into VPC

```bash
cd big-ip-deployment
terraform output -state=../volterra-site/terraform.tfstate --json > volterra-site.auto.tfvars.json
terraform init
terraform apply
```

# Configure BIG-IP

```bash
cd big-ip-configuration
cp ../big-ip-deployment/DO*.json .
terraform output -state=../big-ip-deployment/terraform.tfstate --json > big-ip.auto.tfvars.json
terraform init
terraform apply
```
