#!/bin/sh
# 『壊して学ぶTLS 1.3』第2章 自分だけの認証局をつくる
#
# 本書のコマンドを、節ごとに順番に並べたファイルです。
# まとめて実行するのではなく、[ ] で示した端末に1つずつ貼りつけて実行してください。
#   [端末1: キャプチャ]   docker compose exec server bash
#   [端末2: サーバー]     docker compose exec server bash
#   [端末3: クライアント] docker compose exec client bash
# どの端末も /lab(このフォルダ)で始まります。
# 「Ctrl+Cで止める」とある所では、s_server やキャプチャを止めてから次に進んでください。
exit 0

# ===== 準備 =====

# [ホスト]
docker compose exec server bash

# ===== 2.1 ルートCAをつくる =====

# [サーバーのコンテナ]
openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -out ca.key

openssl req -x509 -new -key ca.key -sha256 -days 3650 \
  -subj "/CN=Lab Root CA" \
  -addext "basicConstraints=critical,CA:TRUE" \
  -addext "keyUsage=critical,keyCertSign,cRLSign" \
  -out ca.crt

# ===== 2.2 サーバー証明書を発行する =====

# [サーバーのコンテナ]
openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -out server.key

openssl req -new -key server.key -subj "/CN=server.lab.test" -out server.csr

# [サーバーのコンテナ] (server.ext は、このリポジトリにも入っています)
cat > server.ext <<'EOF'
basicConstraints=CA:FALSE
keyUsage=critical,digitalSignature
extendedKeyUsage=serverAuth
subjectAltName=DNS:server.lab.test,DNS:localhost,IP:127.0.0.1
EOF

# [サーバーのコンテナ]
openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
  -days 365 -sha256 -extfile server.ext -out server.crt

# [サーバーのコンテナ]
openssl x509 -in server.crt -noout -subject -issuer -dates -ext subjectAltName
