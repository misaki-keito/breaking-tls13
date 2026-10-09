#!/bin/sh
# 『壊して学ぶTLS 1.3』第3章 最初のハンドシェイクを観察する
#
# 本書のコマンドを、節ごとに順番に並べたファイルです。
# まとめて実行するのではなく、[ ] で示した端末に1つずつ貼りつけて実行してください。
#   [端末1: キャプチャ]   docker compose exec server bash
#   [端末2: サーバー]     docker compose exec server bash
#   [端末3: クライアント] docker compose exec client bash
# どの端末も /lab(このフォルダ)で始まります。
# 「Ctrl+Cで止める」とある所では、s_server やキャプチャを止めてから次に進んでください。
exit 0

# ===== 3.1 キャプチャしながらつなぐ =====

# [端末1: キャプチャ]
docker compose exec server bash
tshark -i eth0 -f "tcp port 8443" -w ch3.pcapng

# [端末2: サーバー]
docker compose exec server bash
openssl s_server -accept 8443 -cert server.crt -key server.key -www

# [端末3: クライアント]
docker compose exec client bash
printf "GET / HTTP/1.0\r\n\r\n" | openssl s_client \
  -connect server.lab.test:8443 \
  -servername server.lab.test -CAfile ca.crt \
  -verify_hostname server.lab.test \
  -keylogfile keylog.txt -trace -quiet > ch3_trace.log 2>&1

# [端末3: クライアント]
grep -E "^New|Verify return" ch3_trace.log

# [端末1] のキャプチャをCtrl+Cで止める

# ===== 3.2 まず全体を眺める =====

# [端末1: キャプチャ]
tshark -r ch3.pcapng

# ===== 3.3 ClientHello: クライアントの自己紹介 =====

# [端末1: キャプチャ]
tshark -r ch3.pcapng -Y "frame.number==4" -O tls -V

# ===== 3.6 TLS 1.3なのに「TLS 1.2」と書いてある理由 =====

# [端末1: キャプチャ]
tshark -2 -r ch3.pcapng -Y tls
