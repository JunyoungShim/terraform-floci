# example2

Floci 上で HTTP API Gateway、Lambda、DynamoDB を接続し、REST CRUD を試すためのサンプルです。
Lambda は API Gateway HTTP API v2 のイベントを受け取り、DynamoDB テーブル `exam2-dev-dynamodb` に `UserId` をキーとしてデータを作成、取得、更新、削除します。

## 実行

コマンドは `example2` ディレクトリで実行します。

```powershell
docker compose up -d
terraform init
terraform apply
```

現在 Floci は `FLOCI_STORAGE_MODE: memory` で動作します。
そのため、コンテナーを再起動すると Floci 内のローカル AWS リソースは初期化されます。
コンテナーを起動し直した後は、Terraform state が残っていても実際のリソースが消えている場合があるため、`terraform apply` を再実行します。

## API ID の確認

API Gateway の呼び出し URL には、作成された API ID が含まれます。
この値はリソースを作り直すと変わる可能性があります。

```powershell
terraform state show aws_apigatewayv2_stage.exam2
```

出力から次の値を確認します。

```text
api_id = "5b371f855b"
name   = "exam2-dev-stage-exam2"
```

確認した API ID を PowerShell の環境変数に設定します。
以下の `5b371f855b` は例です。API ID はリソースを作り直すと変わる可能性があるため、必ず自分の環境で確認した値に置き換えます。

```powershell
$env:API_ID = "5b371f855b"
```

Floci の API Gateway 実行 URL は次の形式です。

```text
http://localhost:4566/execute-api/{api_id}/{stage_name}/{path}
```

現在の stage を使う場合、URL は次のように書けます。

```powershell
"http://localhost:4566/execute-api/${env:API_ID}/exam2-dev-stage-exam2/users"
```

## API テスト

この API は `ap-northeast-1` リージョンに作成されます。
Floci の `/execute-api` 呼び出しでリージョンを識別させるため、以下の例ではダミーの SigV4 `Authorization` ヘッダーを付けています。
これは実 AWS の認証を行うための値ではなく、ローカル Floci にリージョンを伝えるための値です。

### Create

```powershell
Invoke-RestMethod -Method Post `
  -Uri "http://localhost:4566/execute-api/${env:API_ID}/exam2-dev-stage-exam2/users" `
  -Headers @{
    Authorization = "AWS4-HMAC-SHA256 Credential=test/20260605/ap-northeast-1/execute-api/aws4_request, SignedHeaders=host, Signature=0000000000000000000000000000000000000000000000000000000000000000"
    "X-Amz-Date" = "20260605T000000Z"
  } `
  -SkipHeaderValidation `
  -ContentType "application/json" `
  -Body '{ "UserId": "user-001", "name": "Alice", "age": 30 }'
```

### Read One

```powershell
Invoke-RestMethod -Method Get `
  -Uri "http://localhost:4566/execute-api/${env:API_ID}/exam2-dev-stage-exam2/users/user-001" `
  -Headers @{
    Authorization = "AWS4-HMAC-SHA256 Credential=test/20260605/ap-northeast-1/execute-api/aws4_request, SignedHeaders=host, Signature=0000000000000000000000000000000000000000000000000000000000000000"
    "X-Amz-Date" = "20260605T000000Z"
  } `
  -SkipHeaderValidation
```

### Read All

```powershell
Invoke-RestMethod -Method Get `
  -Uri "http://localhost:4566/execute-api/${env:API_ID}/exam2-dev-stage-exam2/users" `
  -Headers @{
    Authorization = "AWS4-HMAC-SHA256 Credential=test/20260605/ap-northeast-1/execute-api/aws4_request, SignedHeaders=host, Signature=0000000000000000000000000000000000000000000000000000000000000000"
    "X-Amz-Date" = "20260605T000000Z"
  } `
  -SkipHeaderValidation
```

### Update

```powershell
Invoke-RestMethod -Method Put `
  -Uri "http://localhost:4566/execute-api/${env:API_ID}/exam2-dev-stage-exam2/users/user-001" `
  -Headers @{
    Authorization = "AWS4-HMAC-SHA256 Credential=test/20260605/ap-northeast-1/execute-api/aws4_request, SignedHeaders=host, Signature=0000000000000000000000000000000000000000000000000000000000000000"
    "X-Amz-Date" = "20260605T000000Z"
  } `
  -SkipHeaderValidation `
  -ContentType "application/json" `
  -Body '{ "name": "Alice Updated", "age": 31 }'
```

### Delete

```powershell
Invoke-RestMethod -Method Delete `
  -Uri "http://localhost:4566/execute-api/${env:API_ID}/exam2-dev-stage-exam2/users/user-001" `
  -Headers @{
    Authorization = "AWS4-HMAC-SHA256 Credential=test/20260605/ap-northeast-1/execute-api/aws4_request, SignedHeaders=host, Signature=0000000000000000000000000000000000000000000000000000000000000000"
    "X-Amz-Date" = "20260605T000000Z"
  } `
  -SkipHeaderValidation
```

削除後に同じ `UserId` を再度取得すると、`User not found` の応答を確認できます。

## DynamoDB の確認

全 item を取得します。

```powershell
aws --endpoint-url http://localhost:4566 `
  --region ap-northeast-1 `
  --no-sign-request `
  dynamodb scan `
  --table-name exam2-dev-dynamodb
```

特定の item を取得します。

```powershell
aws --endpoint-url http://localhost:4566 `
  --region ap-northeast-1 `
  --no-sign-request `
  dynamodb get-item `
  --table-name exam2-dev-dynamodb `
  --key '{ "UserId": { "S": "user-001" } }'
```

## メモ

- API Gateway の API ID は作成のたびに変わる可能性があります。README の例が動作しない場合は、`terraform state show aws_apigatewayv2_stage.exam2` で現在の値を確認します。
- DynamoDB の partition key は `UserId` です。
- Lambda handler は `lambda/app.py` の `handler` 関数です。
