locals {
  name = "spot-asg-proxy"
  instance_types = [
    "t2.micro",
    "t3.micro",
    "t3a.micro",
  ]
  ami_id = "ami-04beabd6a4fb6ab6f"
}
