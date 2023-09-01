# OAuth2 Proxy + S3 Proxy の認証付き静的サイト構築のテスト

- 訳あって NLB で TLS 終端して EC2 Instance の OAuth2 Proxy に forward する
- TLS 証明書は ACM で発行するが terraform 外で行い arn を variables で渡す
- OAuth2 Proxy では [GitHub を Provider とする](https://oauth2-proxy.github.io/oauth2-proxy/docs/configuration/oauth_provider#github-auth-provider)
- AutoScaling Group + Spot Instance で Instance 作成時に user-data でセットアップする
- AMI は Amazon Linux 2023
- OAuth2 の credential などは ParameterStore から取得する
- NAT Gateway はお金がもったいないので EC2 に Public address を持たせる
  - VPC Endpoint も使わない


## メモ

AMI ID の探し方

```bash
aws ec2 describe-images \
  --region ap-northeast-1 \
  --owners amazon \
  --query 'reverse(sort_by(Images, &CreationDate))[:1]' \
  --filters 'Name=name,Values=al2023-ami-2023*' 'Name=architecture,Values=x86_64'
```

https://oxyno-zeta.github.io/s3-proxy/

https://github.com/oauth2-proxy/oauth2-proxy


```
trivy config . --tf-exclude-downloaded-modules --skip-dirs .terraform
```
