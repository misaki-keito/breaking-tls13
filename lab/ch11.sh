#!/bin/sh
# 『壊して学ぶTLS 1.3』第11章 TCPの問題か、TLSの問題か
#
# 本書のコマンドを、節ごとに順番に並べたファイルです。
# まとめて実行するのではなく、[ ] で示した端末に1つずつ貼りつけて実行してください。
#   [端末1: キャプチャ]   docker compose exec server bash
#   [端末2: サーバー]     docker compose exec server bash
#   [端末3: クライアント] docker compose exec client bash
# どの端末も /lab(このフォルダ)で始まります。
# 「Ctrl+Cで止める」とある所では、s_server やキャプチャを止めてから次に進んでください。
exit 0

# ===== 11.1 キャプチャの1パケットは、回線の1パケットとは限らない =====

# [サーバーのコンテナ] と [クライアントのコンテナ]
ethtool -k eth0 | grep -E "^(tcp-segmentation|generic-segmentation)"

# [サーバーのコンテナ] と [クライアントのコンテナ] の両方で
ethtool -K eth0 gro off gso off tso off

# [端末1: キャプチャ]
tshark -i eth0 -f "tcp port 8443" -w ch11_split.pcapng

# [端末2: サーバー] (第3章と同じサーバー)
openssl s_server -accept 8443 -cert server.crt -key server.key -www

# [端末3: クライアント]
printf "GET / HTTP/1.0\r\n\r\n" | openssl s_client \
  -connect server.lab.test:8443 -servername server.lab.test -CAfile ca.crt -quiet

# [端末1] のキャプチャをCtrl+Cで止める

# [サーバーのコンテナ] と [クライアントのコンテナ] の両方で 元に戻す
ethtool -K eth0 gro on gso on tso on

# ===== 11.2 ポートが閉じているとき =====

# [端末1: キャプチャ]
tshark -i eth0 -f "tcp port 8443" -w ch11_closed.pcapng

# [端末2] の s_server をCtrl+Cで止める

# [端末3: クライアント]
echo Q | openssl s_client -connect server.lab.test:8443 -brief

# [端末1] のキャプチャをCtrl+Cで止める

# ===== 11.3 通信が届かないとき =====

# [端末1: キャプチャ]
tshark -i eth0 -f "tcp port 8443" -w ch11_drop.pcapng

# [端末2: サーバー] (第3章と同じサーバー)
openssl s_server -accept 8443 -cert server.crt -key server.key -www

# [サーバーのコンテナ]
# サーバーのコンテナで
tc qdisc add dev eth0 root netem loss 100%

# [端末3: クライアント]
echo Q | timeout 8 openssl s_client -connect server.lab.test:8443 -brief

# [端末1] のキャプチャをCtrl+Cで止める

# [サーバーのコンテナ] 元に戻す
tc qdisc del dev eth0 root

# [端末2] の s_server をCtrl+Cで止める
