# example1

Floci 上で Scheduler、Lambda、SQS、S3、Parameter Store を試すためのサンプルです。
Lambda は Parameter Store から SQS キュー名と S3 バケット名を取得し、SQS に入ったメッセージを S3 に JSON ファイルとして保存します。

## 実行

コマンドは `example1` ディレクトリで実行します。

```powershell
docker compose up -d
Compress-Archive -Path .\lambda\app.py -DestinationPath .\lambda.zip -Force
terraform init
terraform plan
terraform apply
```

Terraform は生成した `lambda.zip` を S3 にアップロードし、Lambda はその zip ファイルを参照します。
`terraform plan` または `terraform apply` の前に `lambda.zip` を作成しておく必要があります。

## Floci のメモリ初期化

現在 Floci は `FLOCI_STORAGE_MODE: memory` で動作するため、コンテナを再起動するとローカル AWS リソースは初期化されます。
きれいな状態から作り直す場合は、`example1` ディレクトリで次の順序で実行します。

```powershell
docker compose down
docker compose up -d
Compress-Archive -Path .\lambda\app.py -DestinationPath .\lambda.zip -Force
terraform apply
```

Terraform state はローカルに残るため、再起動後に `terraform apply` を実行すると、Floci 上に存在しないリソースが再作成されます。

## SQS テスト

SQS にテストメッセージを送信します。

```powershell
aws --endpoint-url http://localhost:4566 sqs send-message `
  --queue-url http://localhost:4566/000000000000/exam1-dev-sqs `
  --message-body '{"id":"test-001","message":"hello from sqs"}'
```

Scheduler は 5 分ごとに Lambda を呼び出します。
待たずに確認したい場合は Lambda を手動で実行します。

```powershell
aws --endpoint-url http://localhost:4566 lambda invoke `
  --function-name exam1-dev-sqs-to-s3 `
  .\lambda-output.json
```

S3 に `test-001.json` が保存されているか確認します。

```powershell
aws --endpoint-url http://localhost:4566 s3 ls s3://exam1-dev-sqs
```

## 参考

このサンプルは以下の記事を参考にして作成しました。

- [AWS エミュレーター「Floci」を試す](https://kakakakakku.hatenablog.com/entry/2026/04/13/100157)
- [FlociとTerraformでAWSローカル検証環境を作って永続化まで確認した](https://zenn.dev/curry_katsu/articles/8da508e921345e)
- [LocalStack Community Editionの代替として登場したFlociを試してみた | DevelopersIO](https://dev.classmethod.jp/articles/floci-localstack-alternative-aws-emulator-try/)
