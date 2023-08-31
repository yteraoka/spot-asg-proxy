#-----------------------------------------------------------------------------
# NLB
#-----------------------------------------------------------------------------
resource "aws_security_group" "nlb" {
  vpc_id      = module.vpc.vpc_id
  name        = "${local.name}-nlb"
  description = "for NLB"
  tags = {
    Name = "${local.name}-nlb"
  }
}

resource "aws_vpc_security_group_ingress_rule" "nlb_allow_https" {
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
  security_group_id = aws_security_group.nlb.id
  description       = "Allow TLS inbound traffic"
}

resource "aws_vpc_security_group_egress_rule" "nlb_allow_all" {
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  security_group_id = aws_security_group.nlb.id
  description       = "Allow outbound"
}


#-----------------------------------------------------------------------------
# EC2 Instance
#-----------------------------------------------------------------------------
resource "aws_security_group" "server" {
  vpc_id      = module.vpc.vpc_id
  name        = "${local.name}-server"
  description = "for proxy server"
  tags = {
    Name = "${local.name}-server"
  }
}

resource "aws_vpc_security_group_ingress_rule" "server_allow_http" {
  from_port                    = 8080
  to_port                      = 8080
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.nlb.id
  security_group_id            = aws_security_group.server.id
  description                  = "Allow inbound from NLB"
}

resource "aws_vpc_security_group_egress_rule" "server_allow_all" {
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  security_group_id = aws_security_group.server.id
  description       = "Allow outbound"
}
