#!/bin/sh
# 『壊して学ぶTLS 1.3』第5章 鍵交換と暗号スイートの交渉
#
# 本書のコマンドを、節ごとに順番に並べたファイルです。
# まとめて実行するのではなく、[ ] で示した端末に1つずつ貼りつけて実行してください。
#   [端末1: キャプチャ]   docker compose exec server bash
#   [端末2: サーバー]     docker compose exec server bash
#   [端末3: クライアント] docker compose exec client bash
# どの端末も /lab(このフォルダ)で始まります。
# 「Ctrl+Cで止める」とある所では、s_server やキャプチャを止めてから次に進んでください。
exit 0

# ===== 5.1 鍵交換の方式を選び直させる(HelloRetryRequest) =====

# [端末1: キャプチャ]
tshark -i eth0 -f "tcp port 8443" -w ch5_hrr.pcapng

# [端末2: サーバー]
openssl s_server -accept 8443 -cert server.crt -key server.key -www \
  -groups P-256

# [端末3: クライアント]
printf "GET / HTTP/1.0\r\n\r\n" | openssl s_client \
  -connect server.lab.test:8443 -servername server.lab.test -CAfile ca.crt \
  -groups X25519:P-256 -trace -quiet > ch5_hrr_trace.log 2>&1

# [端末1] のキャプチャと [端末2] の s_server をCtrl+Cで止める

# ===== 5.2 共通の暗号スイートがないとき =====

# [端末1: キャプチャ]
tshark -i eth0 -f "tcp port 8443" -w ch5_nocipher.pcapng

# [端末2: サーバー] と [端末3: クライアント] (中の「# サーバー」「# クライアント」ごとに端末を分ける)
# サーバー
openssl s_server -accept 8443 -cert server.crt -key server.key -www \
  -ciphersuites TLS_AES_128_GCM_SHA256

# クライアント
echo Q | openssl s_client -connect server.lab.test:8443 -brief \
  -servername server.lab.test -CAfile ca.crt \
  -ciphersuites TLS_CHACHA20_POLY1305_SHA256

# [端末2] の s_server をCtrl+Cで止める

# [端末2: サーバー] と [端末3: クライアント] 鍵交換の方式が合わないとき
# サーバー
openssl s_server -accept 8443 -cert server.crt -key server.key -www \
  -groups X25519MLKEM768

# クライアント
echo Q | openssl s_client -connect server.lab.test:8443 -brief \
  -servername server.lab.test -CAfile ca.crt -groups X25519:P-256

# [端末1] のキャプチャと [端末2] の s_server をCtrl+Cで止める

# ===== 5.3 ClientHelloの大きさを比べる =====

# [端末1: キャプチャ]
tshark -i eth0 -f "tcp port 8443" -w ch5_pq.pcapng

# [端末2: サーバー]
openssl s_server -accept 8443 -cert server.crt -key server.key -www

# [端末3: クライアント]
for g in X25519MLKEM768:X25519 X25519 P-256; do
  echo Q | openssl s_client -connect server.lab.test:8443 \
    -servername server.lab.test -CAfile ca.crt -groups $g -brief
done

# [端末1] のキャプチャをCtrl+Cで止める

# [端末1: キャプチャ]
tshark -r ch5_pq.pcapng -Y "tls.handshake.type==1 || tls.handshake.type==2" \
  -T fields -e frame.len -e tls.handshake.type \
  -e tls.handshake.extensions_key_share_group
