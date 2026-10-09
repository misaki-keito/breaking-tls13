#!/bin/sh
# 『壊して学ぶTLS 1.3』第4章 暗号化された通信をWiresharkで復号する
#
# 本書のコマンドを、節ごとに順番に並べたファイルです。
# まとめて実行するのではなく、[ ] で示した端末に1つずつ貼りつけて実行してください。
#   [端末1: キャプチャ]   docker compose exec server bash
#   [端末2: サーバー]     docker compose exec server bash
#   [端末3: クライアント] docker compose exec client bash
# どの端末も /lab(このフォルダ)で始まります。
# 「Ctrl+Cで止める」とある所では、s_server やキャプチャを止めてから次に進んでください。
exit 0

# 第3章でつくった ch3.pcapng と keylog.txt を使います。どちらのコンテナで実行しても構いません。

# ===== 4.1 鍵ログファイル =====

# [コンテナ]
cut -d" " -f1 keylog.txt

# [コンテナ]
tshark -r ch3.pcapng -o tls.keylog_file:keylog.txt -Y tls

# [コンテナ]
tshark -r ch3.pcapng -o tls.keylog_file:keylog.txt -q -z follow,tls,ascii,0

# ===== 4.2 一部の行を外してみる =====

# [コンテナ]
grep -v SERVER_HANDSHAKE keylog.txt > keylog_partial.txt
tshark -r ch3.pcapng -o tls.keylog_file:keylog_partial.txt -Y tls

# [コンテナ]
grep TRAFFIC_SECRET_0 keylog.txt > keylog_app.txt
tshark -r ch3.pcapng -o tls.keylog_file:keylog_app.txt -Y tls
