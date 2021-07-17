# README
2021年7月の福岡県主催ブロックチェーン勉強会のworkshopで用いるサンプルコード

以下の順でtapyrusを用いたDapps開発の基礎を学ぶ

1. Dockerを使った開発モードのtapyrus nodeの立て方と操作方法
2. Gluebyの基礎

# How to make task
lib/tasks/tapyrus.rakeの中身を実装して、Gluebyの使い方を説明する。

## 1. 開発用のtapyrus nodeを立てる
docker-compose.ymlファイルを準備しているので、以下のコマンドを実行してDockerでtapyrus nodeを起動する。

```shell
docker-compose up -d tapyrusd
```
以下のコマンドでtapyrus nodeが起動しているか確認する。

```shell
docker-compose exec tapyrusd tapyrus-cli -conf=/etc/tapyrus/tapyrus.conf getblockchaininfo
```

次のような結果が帰ってきたらnodeは正常に起動している。

```shell
{
  "chain": "1905960821",
  "mode": "dev",
  "blocks": 10,
  "headers": 10,
  "bestblockhash": "6fe809a5990837b0ad20238592e441cdd02299a7a8f8a68aa30dbcc0075990fc",
  "mediantime": 1626450280,
  "verificationprogress": 1,
  "initialblockdownload": false,
  "size_on_disk": 6441,
  "pruned": false,
  "aggregatePubkeys": [
    {
      "03af80b90d25145da28c583359beb47b21796b2fe1a23c1511e443e7a64dfdb27d": 0
    }
  ],
  "warnings": ""
}
```

## 2. Gluebyの設定ファイルを準備する
Gluebyで用意されているタスクを実行してGluebyがtapyrusに接続するための設定ファイルを生成し、適宜修正する。

```shell
bundle exec rails glueby:contract:install
```

上記コマンド実行後、`config/initializers/glueby.rb`が生成されるので、このファイルの内容を以下のように修正する。
port, user, passwordはtapyrus.confで指定してある、rpcport, rpcuser, rpcpasswordと同一にする必要がある。

```ruby
# Edit configuration for connection to tapyrus core
config = {adapter: 'activerecord', schema: 'http', host: '127.0.0.1', port: 12381, user: 'rpcuser', password: 'rpcpassword'}
Glueby::Wallet.configure(config)
```

設定ファイルの修正が終わったら、rails consoleを起動してGluebyを通してtapyrus coreに接続できるか確認する。

まず、rails consoleを起動する。
```shell
bundle exec rails c
```

起動したrails consoleで以下のコマンドを実行する。
```ruby
irb(main):001:0> Glueby::Internal::RPC.client.getblockchaininfo
```

次のような結果が帰って来れば、Gluebyの設定は完了である。

```ruby
=> 
{"chain"=>"1905960821",
 "mode"=>"dev",
 "blocks"=>10,
 "headers"=>10,
 "bestblockhash"=>"6fe809a5990837b0ad20238592e441cdd02299a7a8f8a68aa30dbcc0075990fc",
 "mediantime"=>1626450280,
 "verificationprogress"=>1,
 "initialblockdownload"=>false,
 "size_on_disk"=>6441,
 "pruned"=>false,
 "aggregatePubkeys"=>[{"03af80b90d25145da28c583359beb47b21796b2fe1a23c1511e443e7a64dfdb27d"=>0}],
 "warnings"=>""}
irb(main):002:0>
```

## 3. Gluebyで管理するwalletのセットアップ
今回はActiveRecordを使ってwalletを管理するため、walletのためのDBセットアップを行う。

Gluebyで用意された以下のタスクを実行してmigrationファイルを生成する。

```shell
bundle exec rails g glueby:contract:block_syncer
bundle exec rails g glueby:contract:wallet_adapter
```

次に、migrationをDBに適用する。

```shell
bundle exec rails db:migrate
```

以上で一通りのセットアップは完了である。続いて、lib/tasks/tapyrus.rakeの中身を実装していく。

## 4. createwalletタスクを作成する

Gluebyで何かしらの操作をする場合はwallet単位で扱う事になる。そのため、まずはwallet生成のためのタスクを作る。

tapyrus.rakeの20行めごろにある該当のタスクを以下のように修正する。

```ruby
  task :createwallet => :environment do |task, args|
    wallet = Glueby::Wallet.create # walletの新規作成
    puts "created new wallet: #{wallet.id}" # 新規作成されたwalletのidを出力
  end
```

実際に動作するか確認する。

```shell
bundle exec rails tapyrus:createwallet
```

以下のように新規作成されたwallet idが表示されたら成功である。

```
created new wallet: 7e090c0a3afcb0017bf68b3541ac37cb
```

## 5. generateタスクを作成する

```ruby
  task :generate => :environment do |task, args|
  count = 1 # 生成するブロック数
  authority_key = "c87509a1c067bbde78beb793e6fa76530b6382a4c0241e5e4a9ec0a0f44dc0d3" # minerの秘密鍵
  
  Glueby::Internal::RPC.perform_as("wallet-"+FAUCET_ID) do |client|
    client.generate(count, authority_key)
  end
  puts "#{count} blocks generated."
  puts "after block=#{Glueby::Internal::RPC.client.getblockcount}"
end
```