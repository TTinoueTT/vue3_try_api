FROM ruby:3.2.2-alpine3.17 as builder

# docker-compose.yml で指定した、build時に渡す変数のキーで受け取り実行
ARG WORKDIR

# コンテナ内で利用する環境変数を定義
ENV RUNTIME_PACKAGES="linux-headers libxml2-dev make gcc libc-dev nodejs tzdata gcompat mysql-client mysql-dev sqlite-dev bash git" \
    # "linux-headers libxml2-dev make gcc libc-dev nodejs tzdata postgresql-dev postgresql git"
    # alpine-sdk sqlite-dev mysql-client mysql-dev bash # これらをインストール必要か検討、postgresqlを使用しないでどうするか。
    DEV_PACKAGES="build-base curl-dev" \
    HOME=/${WORKDIR} \
    LANG=C.UTF-8 \
    TZ=Asia/Tokyo

# ENV test（このRUN命令は確認のためなので無くても良い）
RUN echo ${HOME}

WORKDIR ${HOME}

# ホスト側で用意している(Dockerfileと同じディレクトリ階層、つまりビルドコンテキストは指定していない)
# Gemfileという名前がつくファイルを、コンテナ側のWORKDIRから見た相対パスに複製する
COPY Gemfile* ./

RUN apk update && \
    apk upgrade && \
    # --no-cache …ローカルにキャッシュしないようにする、コンテナを軽量に保つ為
    apk add --no-cache ${RUNTIME_PACKAGES} && \
    # --virtual 仮想パッケージ名 …呼び出すパッケージをひとまとめにした仮想パッケージにする
    apk add --virtual build-dependencies --no-cache ${DEV_PACKAGES} && \
    # nokogiri の cannot load such file -- nokogiri/nokogiri (LoadError) 対策
    bundle config set force_ruby_platform true && \
    # bundle install を並列処理で実行(Bundler(v1.4.0.pre.1)から)、 -j4 => --jobs=4 、Gem を並列にインストール
    bundle install -j4 && \
    # 先ほどインストールした仮想パッケージ build-dependencies を削除
    apk del build-dependencies

# 現状の全てのビルドコンテキストのroot階層にあるファイル(Dockerfileと同じ階層のファイル)を複製
COPY . .

# rails s を実行
# CMD ["rails", "server", "-b", "0.0.0.0"]
