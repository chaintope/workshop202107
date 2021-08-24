# README
2021年8月ブロックチェーン勉強会のworkshopで用いるサンプルコード

# How to implement
Ruby on RailsとGluebyを組み合わせて、ブロックチェーンを用いたWeb appを作成するためのサンプルコード。
以下の手順に従って未実装部分を補完することで、シンプルな送金処理が実装できる。

## 1. Web appのスケルトンを起動する
Dockerで準備されている環境を起動し、DBの設定などを行ってWeb Appの実装を行う初期設定を行う。

1. tapyrus nodeとWeb appを起動する

    docker composeコマンドを実行して、tapyrus nodeとWeb Appを起動する。
    ```shell
    docker compose up
    ```
   
2. dbを作成する

    以下のコマンドを実行して、Web Appに必要となるDBテーブルを作成する

    ```shell
    docker compose exec web rails db:migrate
    ```

3. dockerとDBをクリアする

   もし、作業途中で環境をクリアしたい場合は、以下のコマンドを実行してDockerの環境とDBをクリアする。
   その後、環境構築からやり直せば良い。

   ```shell
   docker compose down --rmi all --volumes --remove-orphans
   rm db/development.sqlite3
   ```
   
## 2. ユーザ登録時にWalletを作成する
このWeb Appではユーザ管理のライブラリとして [device](https://github.com/heartcombo/devise) を利用している。
ここでは、ユーザがSing Upした時にwalletが同時に作成されるように実装する。

4. user.rbの`before_create`を実装する

   app/models/user.rbの`before_create`メソッドにUser作成時に同時にWalletが生成されるよう、walletを作成する処理を実装する。
   before_createの内容を以下に修正する。

   ```ruby
   before_create do
     self.wallet_id = Glueby::Wallet.create.id
   end
   ```

   上記、修正後にSign Upから新規ユーザを作成するとtopページ(http://localhost:3000) にwallet_idが表示される。

   これで新規ユーザがSign Upする度にそのユーザ専用のWalletが作成されるようになった。続いて、ユーザのWalletからTPCを受け取るためのアドレスを生成する機能を実装していく。

## 3. 受け取りアドレスの生成機能を実装する

誰かにTapyrus Coin(TPC)を送ってもらうためには、送り先のアドレスを教える必要がある。ここでは各ユーザのWalletに新規のアドレスを生成する機能を実装する。
新規アドレスは`Glueby::Wallet`のメソッドを呼び出すだけで簡単に生成することができる。

Postでリクエストされる、HomeControllerの該当アクション内にこれらの処理を実装する

5. home_controller.rbの`create_receive_address`アクションを実装する

   app/controllers/home_controller.rbの`create_receive_address`メソッドで新しいアドレスが生成されるように以下のように修正する。また、画面上に最新のアドレスを表示するために、アドレスを識別するためのLabelを指定して作成する。

   ```ruby
    def create_receive_address
      @wallet.internal_wallet.receive_address(RECEIVE_ADDRESS_LABEL)
      flash[:notice] = 'Create new receive address'
      redirect_to action: :index
    end
   ```

   この処理はGlueby::Walletの機能を使って新しい秘密鍵を生成している。アドレスとは秘密鍵と対となる公開鍵をあるルールに従って変換したものである。そのため新しい秘密鍵を生成することは、新しいアドレスが生成されることと同義となる。
   
   次に、生成された最新のアドレスを表示する処理を実装する。


6. glueby_helper.rbの`current_receive_address`を実装する

   ここでは生成したアドレスを画面上に表示するための処理を実装する。画面の表示はhome_controller.rbの`index`アクションで行っており、このアクションの中でglueby_helper.rbの`current_receive_address`メソッドを使って最新のアドレスを取得している。

   なので、ここではglueby_helper.rbの`current_receive_address`メソッドの中身を実装することで生成したアドレスを画面上に表示できるようになる。

   app/models/concerns/glueby_helper.rbの`current_receive_address`メソッドを以下のように修正する。

   ```ruby
    def current_receive_address(wallet)
      wallet.internal_wallet.get_addresses(RECEIVE_ADDRESS_LABEL)[-1]
    end
   ```

   このコードではwalletが保有している秘密鍵の一覧から、RECEIVE_ADDRESS_LABELで設定されているlabel名がついた秘密鍵だけを取得し、その中から最後に生成された秘密鍵を取得してアドレス文字列に変換して返すという処理を行っている。

   以上で新しい受け取り用のアドレスを生成して画面に表示する処理が完成した。実際にブラウザからWeb Appを触って確かめてみよう。

## 4. ブロック生成機能を実装する

Walletが受け取りアドレスを生成できるようになったので、次はブロック生成機能を作成する。

Tapyrusなどのブロックチェーンで送金処理を完了する、つまりTransactionの状態を確定するためにはブロックを生成しないといけない。また、送金するためのコインはブロック生成報酬として得られる。
そのため、まずは送金するためのコイン(TPC)を手に入れるためにもブロック生成機能を実装する。

7. glueby_helper.rbの`generate_block`を実装する

   このWeb Appではhome_controller.rbの`generate`アクションでブロックを生成している。このアクションの実装をみると、GluebyHelperの`generate_block`と`sync_block`を呼び出すことで、ブロックの生成とDBへの最新のトランザクションの状態の反映を行っている。

   GluebyHelperの`generate_block`メソッドはまだ未実装なのでここではこのメソッドの中にブロック生成の処理を実装する。

   app/models/concerns/glueby_helper.rbの`generate_block`メソッドを以下のように修正する。

   ```ruby
   def generate_block(wallet)
     count = 1 # 生成するブロック数
     authority_key = "cUJN5RVzYWFoeY8rUztd47jzXCu1p57Ay8V7pqCzsBD3PEXN7Dd4" # minerの秘密鍵
     
     Glueby::Internal::RPC.client.generatetoaddress(count, current_receive_address(wallet), authority_key) # blockを生成(dev modeのみ有効なコマンド)
   end
   ```

   このコードは、Glueby::Internal::RPC.clientを用いてGluebyが接続しているTapyrus nodeに対して任意のJSON-RPCを発行している。ここではブロックを生成したいので、ブロック生成のためのJSON-RPCである、`generatetoaddress`を発行している。

   `generatetoaddress`のJSON-RPCはパラメータとして、生成するブロック数、認証済みのマイナーの秘密鍵、ブロック報酬の受け取りアドレスの3つのパラメータが必要となるためそれぞれ渡している。また、受け取りアドレスとしてはログインしているユーザのWalletにあるアドレスを指定している。そのため、ブロック報酬は実際にブロック生成を実行したユーザに対して支払われる。

   実装が終わったので実際にブラウザからブロックが生成できるか試してみよう。ブロックが正常に生成できればユーザのWalletにTPCが支払われることが確認できるだろう。

## 5. 支払い機能を実装する

最後に、自分が保有しているTPCを任意のアドレスに対して送金する支払い機能を実装する。支払いのためのTransactionを作成するためには、送金する数量(TPC)の残高を保有しているかをチェックし、それらが記録されたUTXOを収集する必要がある。また、UTXOを消費するためにそれぞれの宛先に対応する署名を生成する必要もある。

これらの処理はGlueby::Contract::Paymentを使うことで簡単に実装できる。

8. payment.rbの`transfer`を実装する

    支払い機能を実装するには、Formから送金先のアドレスと送金金額を入力する必要がある。そのため、入力内容のバリデーションを行うために送金処理についてはActiveModelをincludeしたPaymentクラスが責務を追う。

    支払い処理はPaymentクラスの`transfer`メソッドで実装する。

    app/models/concerns/payment.rbの`transfer`メソッドを以下のように修正する。

    ```ruby
    def transfer(wallet)
      Glueby::Contract::Payment.transfer(sender: wallet,
                         receiver_address: self.address,
                         amount: self.amount.to_i * 100_000_000) # convert unit TPC to tapyrus
    end
    ```

    このコードでは、`Glueby::Contract::Payment`を用いてTPCの送金処理を実装している。UTXOの収集や十分な残高のチェックなどは全て`Glueby::Contract::Payment`が処理してくれる。

    これで任意のアドレスに送金が可能となった。実際にブラウザで送金できるか試してみよう。

# その他の情報
* lib/tasks/tapyrus.rakeのより詳細な情報については、 [skeleton](https://github.com/chaintope/workshop202107/tree/skeleton) ブランチを参照
* Gluebyのその他のContractの使用例については、 [all_samples](https://github.com/chaintope/workshop202107/tree/all_samples) ブランチを参照
