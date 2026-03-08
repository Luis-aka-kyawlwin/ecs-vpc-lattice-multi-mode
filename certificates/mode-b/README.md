# Mode B Certificates (Local OpenSSL -> ACM Import)

Mode B HTTPS listener uses a certificate imported into ACM from local OpenSSL files.

## 1) Generate local certificate

```bash
./certificates/mode-b/generate_self_signed.sh
```

Optional custom names:

```bash
./certificates/mode-b/generate_self_signed.sh demo.internal '*.demo.internal'
```

Generated files:

- `certificates/mode-b/out/certificate.crt`
- `certificates/mode-b/out/certificate.key`
- `certificates/mode-b/out/certificate_chain.crt`

## 2) Import into ACM

```bash
AWS_REGION=ap-southeast-1 ./certificates/mode-b/import_to_acm.sh
```

The script prints the `CertificateArn`. Put it in:

- `terraform/environments/mode-b-https/terraform.tfvars`
  - `certificate_arn = "<printed-arn>"`
