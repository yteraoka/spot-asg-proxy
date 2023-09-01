provider "aws" {
  region = "ap-northeast-1"
  default_tags {
    tags = {
      owner     = "teraoka"
      terraform = "spot-asg-proxy"
    }
  }
}

provider "aws" {
  alias  = "virginia"
  region = "us-east-1"
}
