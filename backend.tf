terraform {
  backend "s3" {
    bucket         = "tf-state-885952650506-eu-central-1"   
    key            = "notejam/terraform.tfstate"            
    region         = "eu-central-1"
    dynamodb_table = "tf-lock-885952650506"                 
    encrypt        = true
  }
}