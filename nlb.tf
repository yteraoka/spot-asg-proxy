data "aws_acm_certificate" "cert" {
  domain      = var.domain
  statuses    = ["ISSUED"]
  most_recent = true
}

resource "aws_lb" "lb" {
  name               = local.name
  internal           = false
  load_balancer_type = "network"
  subnets            = module.vpc.public_subnets
  security_groups    = [aws_security_group.nlb.id]

  #checkov:skip=CKV_AWS_152:Cross-zone load balancing は必要か？
  #checkov:skip=CKV_AWS_91:Access Log はコスト削減のため無効
  #checkov:skip=CKV_AWS_150:削除保護は不要
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.lb.arn
  port              = "443"
  protocol          = "TLS"
  certificate_arn   = data.aws_acm_certificate.cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

resource "aws_lb_target_group" "tg" {
  name                   = local.name
  port                   = 8080
  protocol               = "TCP"
  target_type            = "instance"
  preserve_client_ip     = false
  vpc_id                 = module.vpc.vpc_id
  connection_termination = true
  deregistration_delay   = "30"
}

resource "aws_autoscaling_attachment" "asg_tg" {
  autoscaling_group_name = aws_autoscaling_group.asg.id
  lb_target_group_arn    = aws_lb_target_group.tg.arn
}
