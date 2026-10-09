#!/bin/sh
# 『壊して学ぶTLS 1.3』第10章 SNIとALPN
#
# 本書のコマンドを、節ごとに順番に並べたファイルです。
# まとめて実行するのではなく、[ ] で示した端末に1つずつ貼りつけて実行してください。
#   [端末1: キャプチャ]   docker compose exec server bash
#   [端末2: サーバー]     docker compose exec server bash
#   [端末3: クライアント] docker compose exec client bash
# どの端末も /lab(このフォルダ)で始まります。
# 「Ctrl+Cで止める」とある所では、s_server やキャプチャを止めてから次に進んでください。
exit 0

# ===== 10.1 1台のサーバーに2つの名前 =====

# [サーバーのコンテナ] (api.ext は、このリポジトリにも入っています)
openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -out api.key
openssl req -new -key api.key -subj "/CN=api.lab.test" -out api.csr
printf "basicConstraints=CA:FALSE\nkeyUsage=critical,digitalSignature\nextendedKeyUsage=serverAuth\nsubjectAltName=DNS:api.lab.test\n" > api.ext
openssl x509 -req -in api.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
  -days 365 -sha256 -extfile api.ext -out api.crt

# [端末2: サーバー]
openssl s_server -accept 8443 -cert server.crt -key server.key \
  -servername api.lab.test -cert2 api.crt -key2 api.key -www

# [端末3: クライアント]
for n in server.lab.test api.lab.test; do
  echo Q | openssl s_client -connect server.lab.test:8443 \
    -servername $n -CAfile ca.crt -verify_hostname $n -brief
done

# [端末2] の s_server をCtrl+Cで止める

# ===== 10.2 ALPN: TLSの上で何を話すか =====

# [端末1: キャプチャ]
tshark -i eth0 -f "tcp port 8443" -w ch10_alpn.pcapng

# [端末2: サーバー]
openssl s_server -accept 8443 -cert server.crt -key server.key -www \
  -alpn http/1.1

# [端末3: クライアント]
echo Q | openssl s_client -connect server.lab.test:8443 \
  -servername server.lab.test -CAfile ca.crt -alpn h2,http/1.1

# [端末3: クライアント] 一致しないとき
echo Q | openssl s_client -connect server.lab.test:8443 \
  -servername server.lab.test -CAfile ca.crt -alpn h2

# [端末1] のキャプチャをCtrl+Cで止める

# [端末1: キャプチャ]
tshark -r ch10_alpn.pcapng -Y "tls.handshake.type==1" \
  -T fields -e tls.handshake.extensions_alpn_str

# [端末2] の s_server をCtrl+Cで止める
