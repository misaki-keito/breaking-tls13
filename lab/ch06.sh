#!/bin/sh
# 『壊して学ぶTLS 1.3』第6章 証明書の検証を失敗させる
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

# [端末2: サーバー] (第3章と同じサーバー)
openssl s_server -accept 8443 -cert server.crt -key server.key -www

# ===== 6.1 「知らない認証局」 =====

# [端末1: キャプチャ]
tshark -i eth0 -f "tcp port 8443" -w ch6_nocaf.pcapng

# [端末3: クライアント]
echo Q | openssl s_client -connect server.lab.test:8443 -brief \
  -servername server.lab.test -verify_return_error

# [端末1] のキャプチャをCtrl+Cで止める

# ===== 6.2 「名前が違う」 =====

# [端末1: キャプチャ]
tshark -i eth0 -f "tcp port 8443" -w ch6_host.pcapng

# [端末3: クライアント]
echo Q | openssl s_client -connect server.lab.test:8443 -brief \
  -servername www.example.test -CAfile ca.crt \
  -verify_hostname www.example.test -verify_return_error

# [端末1] のキャプチャをCtrl+Cで止める

# ===== 6.3 「期限切れ」 =====

# [サーバーのコンテナ]
openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key \
  -not_before 20250101000000Z -not_after 20260101000000Z \
  -sha256 -extfile server.ext -out expired.crt

# [端末2] の s_server をCtrl+Cで止める

# [端末1: キャプチャ]
tshark -i eth0 -f "tcp port 8443" -w ch6_expired.pcapng

# [端末2: サーバー]
openssl s_server -accept 8443 -cert expired.crt -key server.key -www

# [端末3: クライアント]
echo Q | openssl s_client -connect server.lab.test:8443 -brief \
  -servername server.lab.test -CAfile ca.crt \
  -verify_hostname server.lab.test -verify_return_error

# [端末1] のキャプチャと [端末2] の s_server をCtrl+Cで止める

# ===== 6.4 ネットワーク上ではどう見えるか =====

# [端末1: キャプチャ]
tshark -r ch6_host.pcapng -Y tls

# [端末1: キャプチャ]
tshark -r ch6_host.pcapng -Y tls.alert_message -O tls -V

# ===== 6.6 中間CA証明書の送り忘れ =====

# [サーバーのコンテナ] (int.ext は、このリポジトリにも入っています)
# 中間CA
openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -out int.key
openssl req -new -key int.key -subj "/CN=Lab Intermediate CA" -out int.csr
printf "basicConstraints=critical,CA:TRUE,pathlen:0\nkeyUsage=critical,keyCertSign,cRLSign\n" > int.ext
openssl x509 -req -in int.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
  -days 1825 -sha256 -extfile int.ext -out int.crt

# 中間CAが発行するサーバー証明書
openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -out leaf.key
openssl req -new -key leaf.key -subj "/CN=server.lab.test" -out leaf.csr
openssl x509 -req -in leaf.csr -CA int.crt -CAkey int.key -CAcreateserial \
  -days 365 -sha256 -extfile server.ext -out leaf.crt

# [サーバーのコンテナ]
openssl verify -CAfile ca.crt leaf.crt
openssl verify -CAfile ca.crt -untrusted int.crt leaf.crt

# [端末2: サーバー] 送り忘れたサーバー
openssl s_server -accept 8443 -cert leaf.crt -key leaf.key -www

# [端末3: クライアント]
echo Q | openssl s_client -connect server.lab.test:8443 -brief \
  -servername server.lab.test -CAfile ca.crt -verify_return_error

# [端末3: クライアント] Certificate chainを表示する
echo Q | openssl s_client -connect server.lab.test:8443 \
  -servername server.lab.test -CAfile ca.crt -verify_return_error

# [端末2] の s_server をCtrl+Cで止める

# [端末2: サーバー] 送るように直したサーバー
openssl s_server -accept 8443 -cert leaf.crt -key leaf.key \
  -cert_chain int.crt -www

# [端末3: クライアント]
echo Q | openssl s_client -connect server.lab.test:8443 \
  -servername server.lab.test -CAfile ca.crt -verify_return_error

# [端末2] の s_server をCtrl+Cで止める
