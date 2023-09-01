variable "domain" {
  type        = string
  description = "TLS Certificate のドメイン名"
}

variable "allow_cidrs" {
  type        = list(string)
  description = "WAF で許可する CIDR のリスト"
  default     = []
}

variable "github_repo" {
  type        = string
  description = "OAuth2 Proxy で指定する GITHUB REPOSITORY"
}
