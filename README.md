# Terraform + Floci 実習記録

Terraform でリソースを作成し、動作を確認する過程を記録するリポジトリです。
Floci コンテナーは、実習の目的に応じて単一リソース用とテンプレート実習用に分けて起動します。

## 参考ドキュメント

リソース作成時にオプションや動作を確認したい場合は、Terraform AWS Provider のドキュメントを参照します。

- [AWS Provider resources](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources)


## コンテナー構成

| Compose ファイル | コンテナー | ポート | 用途 |
| --- | --- | --- | --- |
| `compose.yaml` | `floci` | `4566` | 単一リソースの実習 |
| `compose-stg.yaml` | `floci-stg` | `4567` | テンプレートを使った `stg` 環境の実習 |
| `compose-prd.yaml` | `floci-prd` | `4568` | テンプレートを使った `prd` 環境の実習 |

`-stg`、`-prd` が付いていない `floci` コンテナーは、単一リソースを直接作成して確認するために使用します。
`floci-stg`、`floci-prd` コンテナーは、Terraform テンプレートを使って環境ごとの構成を実習し、その内容を記録するために使用します。

## 起動方法

### 単一リソース実習

```powershell
docker compose up -d
```

### テンプレート実習

```powershell
docker compose -f .\compose-stg.yaml up -d
docker compose -f .\compose-prd.yaml up -d
```

## ローカルリソースの確認方法

Floci 上のリソースは、AWS CLI にローカルのエンドポイントを指定して確認します。

```powershell
aws --endpoint-url http://localhost:{port}
```

## 停止方法

```powershell
docker compose down
docker compose -f .\compose-stg.yaml down
docker compose -f .\compose-prd.yaml down
```

## 実習メモ

- 単一リソースの実習は、基本コンテナーである `floci` で行います。
- テンプレート実習では、`stg` と `prd` の環境を分けて比較します。
- 環境ごとの差分は、Terraform の変数、テンプレートファイル、実行結果とあわせて記録します。
