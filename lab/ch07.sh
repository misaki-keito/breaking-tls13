#!/bin/sh
# 『壊して学ぶTLS 1.3』第7章 相互認証(mTLS)
#
# 本書のコマンドを、節ごとに順番に並べたファイルです。
# まとめて実行するのではなく、[ ] で示した端末に1つずつ貼りつけて実行してください。
#   [端末1: キャプチャ]   docker compose exec server bash
#   [端末2: サーバー]     docker compose exec server bash
#   [端末3: クライアント] docker compose exec client bash
# どの端末も /lab(このフォルダ)で始まります。
# 「Ctrl+Cで止める」とある所では、s_server やキャプチャを止めてから次に進んでください。
exit 0

# ===== 7.1 クライアント証明書をつくる =====

# [サーバーのコンテナ] (client.ext は、このリポジトリにも入っています)
openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -out client.key
openssl req -new -key client.key -subj "/CN=client01" -out client.csr
printf "basicConstraints=CA:FALSE\nkeyUsage=critical,digitalSignature\nextendedKeyUsage=clientAuth\n" > client.ext
openssl x509 -req -in client.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
  -days 365 -sha256 -extfile client.ext -out client.crt

# ===== 7.2 証明書を要求するサーバー =====

# [端末1: キャプチャ]
tshark -i eth0 -f "tcp port 8443" -w ch7_mtls.pcapng

# [端末2: サーバー]
openssl s_server -accept 8443 -cert server.crt -key server.key -www \
  -Verify 1 -CAfile ca.crt -verify_return_error

# [端末3: クライアント]
printf "GET / HTTP/1.0\r\n\r\n" | openssl s_client \
  -connect server.lab.test:8443 -servername server.lab.test -CAfile ca.crt \
  -cert client.crt -key client.key -keylogfile keylog_mtls.txt -trace -quiet

# [端末1] のキャプチャをCtrl+Cで止める

# ===== 7.3 証明書を出さないクライアント =====

# [端末1: キャプチャ]
tshark -i eth0 -f "tcp port 8443" -w ch7_nocert.pcapng

# [端末3: クライアント]
(sleep 1; printf "GET / HTTP/1.0\r\n\r\n") | openssl s_client \
  -connect server.lab.test:8443 -servername server.lab.test -CAfile ca.crt \
  -keylogfile keylog_nocert.txt -brief

# [端末1] のキャプチャをCtrl+Cで止める

# ===== 7.4 用途の違う証明書を出す =====

# [端末3: クライアント]
(sleep 1; echo Q) | openssl s_client -connect server.lab.test:8443 -brief \
  -servername server.lab.test -CAfile ca.crt -cert server.crt -key server.key

# [端末2] の s_server をCtrl+Cで止める
