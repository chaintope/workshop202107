# README
2021年7月の福岡県主催ブロックチェーン勉強会のworkshopで用いるサンプルコード

以下の順でtapyrusを用いたDapps開発の基礎を学ぶ

1. Dockerを使った開発モードのtapyrus nodeの立て方と操作方法
2. Gluebyの基礎

# How to make task
lib/tasks/tapyrus.rakeの中身を実装しながら、Gluebyの使い方を説明する。

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
Tapyrus.chain_params = :dev
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

tapyrus.rakeのcreatewalletのタスクを以下のように実装する。

```ruby
  task :createwallet => :environment do |task, args|
    wallet = Glueby::Wallet.create # walletの新規作成
    puts "created new wallet: #{wallet.id}" # 新規作成されたwalletのidを出力
  end
```

walletとは秘密鍵の管理、UTXO(=残高）の管理、Transactionへの署名などを行うものである。Gluebyを利用することで、これらのwalletの管理を任せることができる。

実際に動作するか確認する。

```shell
bundle exec rails tapyrus:createwallet
```

以下のように新規作成されたwallet idが表示されたら成功である。

```
created new wallet: 7e090c0a3afcb0017bf68b3541ac37cb
```

## 5. generateタスクを作成する

devモードの場合は自分だけが参加しているnodeのため、block生成も自分で行う必要がある。
それに対して、testnetやTaaSのPlayground、それから本番のTapyrus NetwrokではSignerがblock生成を行うため、このタスクは必要ない。

blockを生成するためのgenerateタスクを作成する。
なお、このタスクで利用しているRPCコマンドの`generatetoaddress`は、devモードでのみ有効なコマンドである。

tapyrus.rakeのgenerateタスクを以下のように実装する。

```ruby
task :generate => :environment do |task, args|
  count = 1 # 生成するブロック数
  authority_key = "cUJN5RVzYWFoeY8rUztd47jzXCu1p57Ay8V7pqCzsBD3PEXN7Dd4" # minerの秘密鍵

  faucet = Glueby::Wallet.load(FAUCET_ID) # faucetのwalletをロード
  receive_address = faucet.internal_wallet.receive_address # mining報酬の受け取りアドレスを生成
  puts Glueby::Internal::RPC.client.generatetoaddress(count, receive_address, authority_key) # blockを生成(dev modeのみ有効なコマンド)
  
  puts "#{count} blocks generated. send reward to: #{receive_address}" # block生成数と報酬を受け取ったaddressを表示
  puts "after block=#{Glueby::Internal::RPC.client.getblockcount}" # 生成後のblockの高さを表示
end
```

上記処理の内、重要な部分を説明する。

generateタスク内の2行目にある、以下の変数は、minerの秘密鍵を設定している。

```ruby
authority_key = "cUJN5RVzYWFoeY8rUztd47jzXCu1p57Ay8V7pqCzsBD3PEXN7Dd4"
```

tapyrusではPoAを採用しているため、blockを生成するためにはあらかじめ指定されているminerの秘密鍵が必要となる。
今回のサンプルでは、[Docker Image for Tapyrus Core](https://github.com/chaintope/tapyrus-core/blob/master/doc/docker_image.md) の手順にあるものと同じgenesis blockを使っているため、同じminerの秘密鍵を指定する。


同じく、4〜5行目の処理では、block生成報酬を受け取るためのaddressを生成している。

```ruby
  faucet = Glueby::Wallet.load(FAUCET_ID) # faucetのwalletをロード
  receive_address = faucet.internal_wallet.receive_address # mining報酬の受け取りアドレスを生成
```

6行目の処理で、blockを生成するためのRPCコマンドを実行している。
```ruby
  puts Glueby::Internal::RPC.client.generatetoaddress(count, receive_address, authority_key) # blockを生成(dev modeのみ有効なコマンド)
```

作成したgenerateタスクが正常に動作するか確認する。

createwalletを実行し、tapyrus.rakeの12行目のFAUCDT_IDにwallet idを設定する。

```ruby
FAUCET_ID = "7e090c0a3afcb0017bf68b3541ac37cb"
```

generateタスクを実行してblockが生成されるか確認する。
```shell
bundle exec rails tapyrus:generate
```

以下のような実行結果が出力されたら、generateタスクの作成に成功している。
```shell
725c51eabe94c89a09f9e3ede1ebaf056288aa630faa593b02d85cb94851831f
1 blocks generated. send reward to: msitqVtNVSxW9uV4QdDAJEMhLSJwx9JSQf
after block=2
```

## 6. faucetタスクを作成する

block生成報酬をfaucetのwalletからsenderのwalletに送金するためのfaucetタスクを作成する。

tapyrusでコインを送金するtransactionを作成するためには、
1. utxoのリストから送金したいコインの量以上のunspent txを集める。
1. 1.で集めたunspent txのtx.outをtx.inに指定した新しいtransactionを作成する。
1. 2.で作成したtransactionのtx.out[0]に送金先の公開鍵や送金するコインの量を設定する。
1. 2.で作成したtransactionのtx.out[1]にお釣り量と自分宛の公開鍵を設定する。
1. 2.で作成したtransactionのtx.inに署名をつける。

という手順が必要になるが、それらをまとめて行ってくれる、Glueby::Contract::Paymentを利用して送金処理を実装する。

tapyrus.rakeのfaucetタスクを以下のように実装する。
```ruby
task :faucet => :environment do |task, args|
    sender = Glueby::Wallet.load(FAUCET_ID) # 送金元のwalletとしてfaucetを指定
    receiver = Glueby::Wallet.load(SENDER_ID) # 送金先としてsenderを指定
    address = receiver.internal_wallet.receive_address # senderの受け取りaddressを生成
    puts "receiver address = #{address}"
    # GluebyのPayment contractを使って1TPCを送金する。
    tx = Glueby::Contract::Payment.transfer(sender: sender,
                                            receiver_address: address,
                                            amount: 100_000_000)
    puts "transaction.id = #{tx.txid}"
end
```

Glueby::Contract::Paymentを利用するためには、送信元のwalletと送信先のaddressとTPCの数量を指定する必要がある。

faucetタスクの１行目で、送信元のwalletをロードしている。
```ruby
sender = Glueby::Wallet.load(FAUCET_ID) # 送金元のwalletとしてfaucetを指定
```

2〜3行目で送信先のaddressを生成している。
```ruby
receiver = Glueby::Wallet.load(SENDER_ID) # 送金先としてsenderを指定
address = receiver.internal_wallet.receive_address # senderの受け取りaddressを生成
```

6〜8行目で、1TPC(= 100,000,000tapyrus)を送金している。
```ruby
tx = Glueby::Contract::Payment.transfer(sender: sender,
                                        receiver_address: address,
                                        amount: 100_000_000)
```

作成したfaucetタスクの動作を確認する。

動作確認をするためにはsenderのwalletが必要なため、まずはsenderのwalletを作成する。

4.で作成した、createwalletを実行してwalletを新規作成する。

```shell
bundle exec rails tapyrus:createwallet
> created new wallet: 07945992e28ab078d1854830f4357fa1
```

表示されたwallet idをtapyrus.rakeの14行目に定義してある、SENDER_IDに設定する。
```ruby
SENDER_ID = "07945992e28ab078d1854830f4357fa1"
```

そして、faucetタスクを実行する。
```shell
bundle exec rails tapyrus:faucet
```

以下のような実行結果が出力されたら、faucetタスクの作成に成功している。
```shell
receiver address = mwz89x4C5QhEH5CKjz3QBBQXJ7yB8iJnp3
[Warning] Use key_type parameter instead of compressed. compressed parameter removed in the future.
transaction.id = e80dee159be38364ac44a889132fafea6ff3b1a905b3a5be0bc1f0a6a012c8da
```

また、以下のようにtapyrus nodeのRPCのgetrawtransactionコマンドで発行された送金transactionを確認できる。
```shell
docker-compose exec tapyrusd tapyrus-cli -conf=/etc/tapyrus/tapyrus.conf getrawtransaction e80dee159be38364ac44a889132fafea6ff3b1a905b3a5be0bc1f0a6a012c8da 1

> {
  "txid": "e80dee159be38364ac44a889132fafea6ff3b1a905b3a5be0bc1f0a6a012c8da",
  "hash": "49934dabf31334d023077d0ddbd160318bbbb27d975d15400f8a640c074a01e9",
  "features": 1,
  "size": 219,
  "vsize": 219,
  "weight": 876,
  "locktime": 0,
  "vin": [
    {
      "txid": "55b276903ec0d1e8443b86323c9c839f0c81d888773927a0bd648dd1503b891a",
      "vout": 0,
      "scriptSig": {
        "asm": "21ccfc43558cf38df48c07f08168542c046902c542e6ceca0a1686854b9ae613c15489d0a0173eee532dda85527d90e6b471fd41b6fe87964ba6c3021d1a2595[ALL] 027b1ab994548356b2c09690e5adcfa724a1b5dd72a22fe73270dffdbfcca179fb",
        "hex": "4121ccfc43558cf38df48c07f08168542c046902c542e6ceca0a1686854b9ae613c15489d0a0173eee532dda85527d90e6b471fd41b6fe87964ba6c3021d1a25950121027b1ab994548356b2c09690e5adcfa724a1b5dd72a22fe73270dffdbfcca179fb"
      },
      "sequence": 4294967295
    }
  ],
  "vout": [
    {
      "value": 1.00000000,
      "n": 0,
      "scriptPubKey": {
        "asm": "OP_DUP OP_HASH160 b4a57975bd7e91376a30faa0f0aed0651ea08ade OP_EQUALVERIFY OP_CHECKSIG",
        "hex": "76a914b4a57975bd7e91376a30faa0f0aed0651ea08ade88ac",
        "reqSigs": 1,
        "type": "pubkeyhash",
        "addresses": [
          "mwz89x4C5QhEH5CKjz3QBBQXJ7yB8iJnp3"
        ]
      }
    },
    {
      "value": 49.00000000,
      "n": 1,
      "scriptPubKey": {
        "asm": "OP_DUP OP_HASH160 77e81347441b4552a5c7b71fac74683d8bce174c OP_EQUALVERIFY OP_CHECKSIG",
        "hex": "76a91477e81347441b4552a5c7b71fac74683d8bce174c88ac",
        "reqSigs": 1,
        "type": "pubkeyhash",
        "addresses": [
          "mrSxikr8wLQQxiQxVgFGab1WQLJEY4owYY"
        ]
      }
    }
  ],
  "hex": "01000000011a893b50d18d64bda027397788d8810c9f839c3c32863b44e8d1c03e9076b25500000000644121ccfc43558cf38df48c07f08168542c046902c542e6ceca0a1686854b9ae613c15489d0a0173eee532dda85527d90e6b471fd41b6fe87964ba6c3021d1a25950121027b1ab994548356b2c09690e5adcfa724a1b5dd72a22fe73270dffdbfcca179fbffffffff0200e1f505000000001976a914b4a57975bd7e91376a30faa0f0aed0651ea08ade88ac00111024010000001976a91477e81347441b4552a5c7b71fac74683d8bce174c88ac00000000"
}
```

## 7. paymentタスクを作成する

senderからreceiverにコインを送金するためのpaymentタスクを作成する。
paymentタスクは送金元のwalletと受け取りのwalletを変えただけで、内容はfaucetタスクと全く同一のため、解説は割愛する。

tapyrus.rakeのpaymentタスクを以下のように実装する。
```ruby
    sender = Glueby::Wallet.load(SENDER_ID) # senderのwalletをロード
    receiver = Glueby::Wallet.load(RECEIVER_ID) # receiverのwalletをロード
    address = receiver.internal_wallet.receive_address # receiverの受け取りaddressを生成
    puts "receiver address = #{address}"
    tx = Glueby::Contract::Payment.transfer(sender: sender,
                                       receiver_address: address,
                                       amount: 10_000_000) # 0.1TPCを送金
    puts "transaction.id = #{tx.txid}"
```

早速動作を確認する。今、作成したpaymentタスクを実行する。

まず、receiverのwalletを生成する。
```shell
bundle exec rails tapyrus:createwallet
> created new wallet: 016d451fa5b19fc8017ad0351eb49149
```

新しく生成されたwallet idをtapyrus.rakeの16行目に定義してあるRECEIVER_IDに設定する。
```ruby
RECEIVER_ID = "016d451fa5b19fc8017ad0351eb49149"
```

そして、paymentタスクを実行する。
```shell
bundle exec rails tapyrus:payment
```

しかしながら、以下のようにエラーが表示される。
```shell
receiver address = mpLxiRumzdJyV8JWFp7miSx2g16pHpMMrf
rails aborted!
Glueby::Contract::Errors::InsufficientFunds: Glueby::Contract::Errors::InsufficientFunds
/Users/nakajo/work/fukuoka_bc_workshop202107_202110/workshop/vendor/bundle/ruby/3.0.0/gems/glueby-0.4.1/lib/glueby/internal/wallet.rb:132:in `collect_uncolored_outputs'
/Users/nakajo/work/fukuoka_bc_workshop202107_202110/workshop/vendor/bundle/ruby/3.0.0/gems/glueby-0.4.1/lib/glueby/contract/payment.rb:41:in `transfer'
/Users/nakajo/work/fukuoka_bc_workshop202107_202110/workshop/lib/tasks/tapyrus.rake:58:in `block (2 levels) in <main>'
・・・以下省略・・・
```

これは、送信元であるsenderのwalletに十分なコインの量が存在していないからである。

が、ここまでの作業で、faucetから1TPCをsenderに送金している。
しかしながら、そのコインはまだsenderに届いていない。その理由としては、transactionを発行してからまだ一度もblockが作成されていないためである。

ということで、generateタスクを実行実行してfaucetからの送金transactionを確定させる。
```shell
bundle exec rails tapyrus:generate

> d1880a8d446ab03d83cfc37eeb16c6e5650f15df96a165a988020b55f96ffb84
> 1 blocks generated. send reward to: mo1bestcorKS8UKuF2hJjNdiRF7Zyt399f
> after block=16
```

これで、faucetからsenderに1TPC送金するtransactionがblockに取り込まれ、実際に送金が完了した。
しかしながら、この状態はまだGlueby::Walletには反映されていない。

そのため、続いてGluebyで用意されている以下のコマンドを実行して、tapyrus nodeの状態をGlueby::Walletに（つまりはDB）に反映させる。

```shell
bundle exec rails glueby:contract:block_syncer:start

> success in synchronization (block height=16)
```

これで、senderのGlueby::Walletにも1TPCが送金された情報が反映された。

なので、再度paymentタスクを実行して、senderからreceiverにTPCが送金できることを確認する。
```shell
bundle exec rails tapyrus:payment
```

以下のような実行結果が表示されたら送金に成功している。
```shell
receiver address = mnVKA5Vgk1F6ppov32SczbEYH8YHx2Q2H6
[Warning] Use key_type parameter instead of compressed. compressed parameter removed in the future.
[Warning] Use key_type parameter instead of compressed. compressed parameter removed in the future.
transaction.id = 0873609e17c76912375afc1559c73bb9c11d01fe3303232ecc41bbf45479e793
```

## 8. getbalanceタスクを作成する

各walletにいくつのTPCが残っているかを確認するために、getbalanceタスクを作成する。
tapyrus.rakeのgetbalanceタスクを以下のように実装する。
```ruby
task :getbalance => :environment do |task, args|
    faucet = Glueby::Wallet.load(FAUCET_ID)
    sender = Glueby::Wallet.load(SENDER_ID)
    receiver = Glueby::Wallet.load(RECEIVER_ID)
    puts "faucet balance=#{faucet.balances}"
    puts "sender balance=#{sender.balances}"
    puts "receiver balance=#{receiver.balances}"
end
```

残高の管理もGlueby::Walletが自動で管理している。そのためそれぞれのwalletをロードして、balances関数を呼び出すだけでwalletに入っているTPC（さらにはtoken）の残高を確認することができる。

作成した、getbalanceタスクを実行して確認する。
```shell
bundle exec rails tapyrus:getbalance
```

以下のような結果が表示される。
```shell
faucet balance={""=>78870070000}
sender balance={}
receiver balance={}
```

先程、senderからreceiverに0.1TPC送金したが、その内容が反映されていない。
これは、faucetタスクを実行した時と同様に、送金transactionを発行してからまだblockが生成されていないためである。

先程と同様に、generateおよび、glueby:contract:block_syncer:startタスクを実行して、transactionを確定してwalletに内容を反映させる。
```shell
bundle exec rails tapyrus:generate
> 8cf9244b2ce014bf5abaa96babeac8a884faa2070e68f6b5fef558f3d15c019c
> 1 blocks generated. send reward to: n2nU1WMnmPnpuj5eF5XoYMPs77SnMgCFfn
> after block=17

bundle exec rails glueby:contract:block_syncer:start
> success in synchronization (block height=17)
```

再度getblanaceタスクを実行すると、senderとreceiverのwalletに残高が反映されていることが確認できる。
```shell
bundle exec rails tapyrus:getbalance
> faucet balance={""=>83870080000}
> sender balance={""=>90000000}
> receiver balance={""=>10000000}
```

## 9. getutxocountタスクを作成する
getbalanceを実行した時に気づいた人がいるかもしれないが、1TPCを持っているsenderが0.1TPCをreceiverに送金した時、blockが生成されるまで残高が0TPCとなっている。

tapyrusでは、コインを送金する回数はUTXO（Unspent Transaction Output)の数に依存するためである。
なので、このutxoの数を確認するためのタスクを作成する。

tapyrus.rakeのgetutxocountを以下のように実装する。
```ruby
task :getutxocount => :environment do |task, args|
  sender = Glueby::Wallet.load(SENDER_ID)
  receiver = Glueby::Wallet.load(RECEIVER_ID)
  puts "sender utxo=#{sender.internal_wallet.list_unspent.size}"
  puts "receiver utxo=#{receiver.internal_wallet.list_unspent.size}"
end
```
UTXOについても、Glueby::Walletが管理している。そのため、getbalanceと同様にGlueby::Walletをロードして,internal_walletのlist_unspent関数を呼び出すことで確認できる。

UTXOの数を増やすためには、tx.outを複数持つtransactionを生成すれば良い。例えば、Glueby::Contract::Paymentを参考にして、以下のようなクラスを実装すれば、複数のtx.outを持つtransactionが発行可能となる。
```ruby
  class MultiPayment
    extend Glueby::Contract::TxBuilder

    class << self
      def transfers(sender:, receiver_addresses:, amounts:, fee_estimator: Glueby::Contract::FixedFeeEstimator.new)
        raise "Unmatched receiver_addresses.len and amounts.len." if receiver_addresses.size != amounts.size
        total_amount = amounts.sum
        raise Glueby::Contract::Errors::InvalidAmount unless total_amount.positive?

        tx = Tapyrus::Tx.new
        dummy_fee = fee_estimator.fee(dummy_tx(tx))

        sum, outputs = sender.internal_wallet.collect_uncolored_outputs(dummy_fee + total_amount)
        fill_input(tx, outputs)

        receiver_addresses.each_with_index do |receiver_address, i|
          amount = amounts[i]

          receiver_script = Tapyrus::Script.parse_from_addr(receiver_address)
          tx.outputs << Tapyrus::TxOut.new(value: amount, script_pubkey: receiver_script)
        end
        fee = fee_estimator.fee(tx)

        fill_change_tpc(tx, sender, sum - fee - total_amount)

        tx = sender.internal_wallet.sign_tx(tx)

        sender.internal_wallet.broadcast(tx)
      end
    end
  end
```

# 他のサンプルについて
GluebyにはPaymentの他に以下のContractも用意されている。
 * Glueby::Contract::Timestamp
   * tapyrus上に任意のデータが存在していたことを刻むためのContract
 * Glueby::Contract::Token
   * tapyrus上で任意のtoken(NFTも)を発行するためのContract
    
これらのサンプルについては以下のブランチにあるlib/tasks/tapyrus.rakeを参照のこと。
https://github.com/chaintope/workshop202107/tree/all_samples