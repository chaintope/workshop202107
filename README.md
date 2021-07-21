# README
2021年7月ブロックチェーン勉強会のworkshopで用いるサンプルコード

1. Dockerを使った開発モードのtapyrus nodeの立て方と操作方法については以下を参照
   * [Tapyrus CoreのQuick Start](https://github.com/chaintope/tapyrus-core/blob/master/doc/docker_image.md#dev-mode)を参照
   
2. Gluebyの使い方については以下を参照
   * [glueby/README.md](https://github.com/chaintope/glueby/blob/master/README.md)を参照

# How to use
Gluebyの一番基本的なContractであるGlueby::Contract::Paymentを用いた送金処理をrake taskとして実装している。
以下の手順に従っでtaskを試すことができる。

1. tapyrus nodeを起動する
    ```shell
    docker-compose up -d tapyrusd
    ```
1. dbを作成する。
    ```shell
    bundle exec rails db:migrate
    ```

1. faucet, sender, receiverのwalletを生成する。以下のコマンドを3回発行する。
    ```shell
   bundle exec rails tapyrus:createwallet
    ```

1. 生成されたwallet idをlib/tasks/tapyrus.rakeのFAUCET_ID, SENDER_ID, RECEIVER_IDに設定する。
1. blockを生成する。
    ```shell
   bundle exec rails tapyrus:generate
    ```

1. faucetからTCPを引き出す(faucetからsenderに送金する)。
    ```shell
    bundle exec rails tapyrus:faucet
    ```

1. blockを生成してtransactionを確定させる。
    ```shell
    bundle exec rails tapyrus:generate
    bundle exec rails glueby:contract:block_syncer:start
    ```

1. senderからreceiverにTCPを送金する。
    ```shell
    bundle exec rails tapyrus:payment
    bundle exec rails tapyrus:generate
    bundle exec rails glueby:contract:block_syncer:start
    ```

1. faucet, sender, receiverの残高を確認する。
    ```shell
    bundle exec rails tapyrus:getbalance
    ```

# その他の情報
* lib/tasks/tapyrus.rakeのより詳細な情報については、 [skeleton](https://github.com/chaintope/workshop202107/tree/skeleton) ブランチを参照
* Gluebyのその他のContractの使用例については、 [all_samples](https://github.com/chaintope/workshop202107/tree/all_samples) ブランチを参照
