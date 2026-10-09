#!/bin/sh
# 『壊して学ぶTLS 1.3』第9章 古いTLSとダウングレード防止
#
# 本書のコマンドを、節ごとに順番に並べたファイルです。
# まとめて実行するのではなく、[ ] で示した端末に1つずつ貼りつけて実行してください。
#   [端末1: キャプチャ]   docker compose exec server bash
#   [端末2: サーバー]     docker compose exec server bash
#   [端末3: クライアント] docker compose exec client bash
# どの端末も /lab(このフォルダ)で始まります。
# 「Ctrl+Cで止める」とある所では、s_server やキャプチャを止めてから次に進んでください。
exit 0

# ===== 9.1 TLS 1.2で話すサーバー =====

# [端末1: キャプチャ]
tshark -i eth0 -f "tcp port 8443" -w ch9_tls12.pcapng

# [端末2: サーバー]
openssl s_server -accept 8443 -cert server.crt -key server.key -www -tls1_2

# [端末3: クライアント]
echo Q | openssl s_client -connect server.lab.test:8443 -brief \
  -servername server.lab.test -CAfile ca.crt

# ===== 9.2 バージョンが合わないとき =====

# [端末3: クライアント]
echo Q | openssl s_client -connect server.lab.test:8443 -brief \
  -servername server.lab.test -CAfile ca.crt -tls1_3

# [端末3: クライアント]
echo Q | openssl s_client -connect server.lab.test:8443 -brief \
  -servername server.lab.test -CAfile ca.crt -tls1_1

# [端末1] のキャプチャと [端末2] の s_server をCtrl+Cで止める

# ===== 9.3 ダウングレード防止の印 =====

# [端末1: キャプチャ]
tshark -i eth0 -f "tcp port 8443" -w ch9_sentinel.pcapng

# [端末2: サーバー] と [端末3: クライアント] (中の「# サーバー」「# クライアント」ごとに端末を分ける)
# サーバー(TLS 1.3まで対応)
openssl s_server -accept 8443 -cert server.crt -key server.key -www

# クライアント(TLS 1.2まで)
echo Q | openssl s_client -connect server.lab.test:8443 -brief \
  -servername server.lab.test -CAfile ca.crt -tls1_2

# [端末1] のキャプチャをCtrl+Cで止める

# [端末1: キャプチャ]
tshark -r ch9_sentinel.pcapng -Y "tls.handshake.type==2" \
  -T fields -e tls.handshake.random

# [端末2] の s_server をCtrl+Cで止める
