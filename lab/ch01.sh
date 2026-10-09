#!/bin/sh
# 『壊して学ぶTLS 1.3』第1章 実験環境をつくる
#
# 本書のコマンドを、節ごとに順番に並べたファイルです。
# まとめて実行するのではなく、[ ] で示した端末に1つずつ貼りつけて実行してください。
#   [端末1: キャプチャ]   docker compose exec server bash
#   [端末2: サーバー]     docker compose exec server bash
#   [端末3: クライアント] docker compose exec client bash
# どの端末も /lab(このフォルダ)で始まります。
# 「Ctrl+Cで止める」とある所では、s_server やキャプチャを止めてから次に進んでください。
exit 0

# ===== 1.1 Dockerを用意する =====

# [ホスト]
docker version
docker compose version

# ===== 1.2 実験用のコンテナをつくる =====

# [ホスト] 本書のリポジトリを使う場合
git clone https://github.com/misaki-keito/breaking-tls13.git
cd breaking-tls13

# [ホスト]
docker compose up -d --build

# ===== 1.3 コンテナに入って確かめる =====

# [ホスト]
docker compose exec client bash

# [クライアントのコンテナ]
openssl version
tshark --version | head -1
getent hosts server.lab.test
