module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  #checkov:skip=CKV_TF_1:commit までは指定しない
  version = "v5.1.1"

  name = local.name
  cidr = "10.0.0.0/16"

  azs            = ["ap-northeast-1a", "ap-northeast-1c"]
  public_subnets = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = false
  enable_vpn_gateway = false
}
