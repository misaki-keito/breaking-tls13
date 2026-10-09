#!/bin/sh
# 『壊して学ぶTLS 1.3』第8章 セッション再開と0-RTT
#
# 本書のコマンドを、節ごとに順番に並べたファイルです。
# まとめて実行するのではなく、[ ] で示した端末に1つずつ貼りつけて実行してください。
#   [端末1: キャプチャ]   docker compose exec server bash
#   [端末2: サーバー]     docker compose exec server bash
#   [端末3: クライアント] docker compose exec client bash
# どの端末も /lab(このフォルダ)で始まります。
# 「Ctrl+Cで止める」とある所では、s_server やキャプチャを止めてから次に進んでください。
exit 0

# ===== 8.1 NewSessionTicketとPSK =====

# [端末2: サーバー]
openssl s_server -accept 8443 -cert server.crt -key server.key -www -early_data

# [端末3: クライアント]
printf "GET / HTTP/1.0\r\n\r\n" | openssl s_client \
  -connect server.lab.test:8443 -servername server.lab.test -CAfile ca.crt \
  -sess_out sess.pem -quiet
openssl sess_id -in sess.pem -noout -text

# [端末1: キャプチャ] チケットで再接続する
tshark -i eth0 -f "tcp port 8443" -w ch8_resume.pcapng

# [端末3: クライアント]
printf "GET / HTTP/1.0\r\n\r\n" | openssl s_client \
  -connect server.lab.test:8443 -servername server.lab.test -CAfile ca.crt \
  -sess_in sess.pem -keylogfile keylog_resume.txt

# [端末1] のキャプチャをCtrl+Cで止める

# ===== 8.2 0-RTTとリプレイ攻撃 =====

# [端末1: キャプチャ]
tshark -i eth0 -f "tcp port 8443" -w ch8_0rtt.pcapng

# [端末3: クライアント]
printf "GET /early HTTP/1.0\r\n\r\n" > early.txt

# [端末3: クライアント]
# チケットを取る
printf "GET / HTTP/1.0\r\n\r\n" | openssl s_client \
  -connect server.lab.test:8443 -servername server.lab.test -CAfile ca.crt \
  -sess_out t.pem -quiet

# 0-RTTで送る
openssl s_client -connect server.lab.test:8443 -servername server.lab.test \
  -CAfile ca.crt -sess_in t.pem -early_data early.txt \
  -keylogfile keylog_0rtt.txt < /dev/null

# [端末3: クライアント] 同じチケットで、もう一度送る
openssl s_client -connect server.lab.test:8443 -servername server.lab.test \
  -CAfile ca.crt -sess_in t.pem -early_data early.txt < /dev/null

# [端末2] の s_server をCtrl+Cで止める

# [端末2: サーバー] 対策を外す
openssl s_server -accept 8443 -cert server.crt -key server.key -www \
  -early_data -no_anti_replay

# [端末3: クライアント] (t.pem を取り直すところから繰り返す)
# チケットを取る
printf "GET / HTTP/1.0\r\n\r\n" | openssl s_client \
  -connect server.lab.test:8443 -servername server.lab.test -CAfile ca.crt \
  -sess_out t.pem -quiet

# 0-RTTで送る
openssl s_client -connect server.lab.test:8443 -servername server.lab.test \
  -CAfile ca.crt -sess_in t.pem -early_data early.txt \
  -keylogfile keylog_0rtt.txt < /dev/null

# [端末3: クライアント]
openssl s_client -connect server.lab.test:8443 -servername server.lab.test \
  -CAfile ca.crt -sess_in t.pem -early_data early.txt < /dev/null

# [端末1] のキャプチャと [端末2] の s_server をCtrl+Cで止める
