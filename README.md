# breaking-tls13

『壊して学ぶTLS 1.3 ── パケットで語れるエンジニアになる』(三崎慶人)のサンプルファイルです。

本書の実験環境(TLSのサーバーとクライアントの2台のコンテナ)を、このリポジトリから作れます。

## 必要なもの

- Docker(Windows/MacはDocker Desktop、LinuxはDocker Engineとcompose plugin)

## 使い方

```bash
git clone https://github.com/misaki-keito/breaking-tls13.git
cd breaking-tls13
docker compose up -d --build

docker compose exec server bash   # サーバー側
docker compose exec client bash   # クライアント側
```

`lab` フォルダは、両方のコンテナの `/lab` として共有されます。証明書、キャプチャ、鍵ログはここにできます。

| コンテナ | IPアドレス | 名前 |
|---|---|---|
| server | 172.28.0.10 | server.lab.test |
| client | 172.28.0.20 | |

## ファイル

| ファイル | 内容 | 本書 |
|---|---|---|
| `Dockerfile` | Debian 13 + OpenSSL、tshark、iproute2、ethtool | 第1章 |
| `compose.yaml` | server/clientの2台構成 | 第1章 |
| `lab/server.ext` | サーバー証明書の拡張情報 | 第2章 |
| `lab/int.ext` | 中間CA証明書の拡張情報 | 第6章 |
| `lab/client.ext` | クライアント証明書の拡張情報 | 第7章 |
| `lab/api.ext` | 2つ目の名前のサーバー証明書の拡張情報 | 第10章 |
| `lab/ch01.sh`〜`lab/ch11.sh` | 各章のコマンドを、節ごとに順番に並べたもの | 第1〜11章 |
| `lab/cleanup.sh` | 後片付けのコマンド | 付録B |

`lab/chNN.sh` は、まとめて実行するものではありません。ファイルの中の `# [端末2: サーバー]` のような見出しにしたがって、コマンドを1つずつ、その端末に貼りつけて実行してください。コマンドは本書と同じです。

## 注意

- 実験は、自分で管理する環境の中だけで行ってください
- `lab` フォルダには、実験でつくった秘密鍵や鍵ログが残ります。不要になったら削除してください。これらは `.gitignore` でコミットされないようにしています
- 本書の出力は OpenSSL 3.5.7 と tshark 4.4.19 で確認しています

## 後片付け

```bash
docker compose down
```

## ライセンス

MIT License(`LICENSE` を参照)
