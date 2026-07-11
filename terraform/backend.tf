# ==================== BACKEND CONFIGURATION ====================

# terraform {
#   backend "s3" {
#     bucket         = "hasa-app-terraform-state-YOUR-ACCOUNT-ID"
#     key            = "prod/terraform.tfstate"
#     region         = "us-east-1"
#     dynamodb_table = "hasa-app-terraform-locks"
#     encrypt        = true
#   }
# }

# INSTRUCTIONS:
# 1. First run: terraform init (stores state locally)
# 2. First run: terraform apply (creates infrastructure + S3 bucket)
# 3. Replace YOUR-ACCOUNT-ID in bucket name above with your AWS Account ID
# 4. Uncomment the backend block above
# 5. Run: terraform init (will ask to migrate state to S3)
# 6. Type: yes (to migrate)