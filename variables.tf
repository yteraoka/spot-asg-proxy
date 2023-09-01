variable "domain" {
  type        = string
  description = "TLS Certificate のドメイン名"
}

variable "allow_cidrs" {
  type        = list(string)
  description = "WAF で許可する CIDR のリスト"
  default     = []
}
