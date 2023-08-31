provider "aws" {
  region = "ap-northeast-1"
  default_tags {
    tags = {
      owner     = "teraoka"
      terraform = "spot-asg-proxy"
    }
  }
}
