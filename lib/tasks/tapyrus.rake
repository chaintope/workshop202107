### *How to use this
# 1. `bundle exec rails tapyrus:createwallet` を3回実行する
# 2. 生成されたwallet_idをこのファイルのFAUCET_ID, SENDER_ID, RECEIVER_IDに指定する
# 3. `bundle exec rails tapyrus:generate` を実行してブロックを生成
# 4. `bundle exec rails tapyrus:faucet` を実行してfaucetからTPCを引き出す
# 5. `bundle exec rails tapyrus:generate` を実行して 4.のtransactionを確定させる
# 6. `bundle exec rails tapyrus:payment` を実行してsenderからreceiverにTPCを送金する
# 7. `bundle exec rails tapyrus_generate` を実行して6. のtransactionを確定させる
########################################

# faucetのwallet_id。mining報酬が溜まっていくwallet。
FAUCET_ID = ""
# サンプルで使うsender & aliceのwallet_id。
SENDER_ID = ""
# サンプルで使うreceiver & bobのwallet_id。
RECEIVER_ID = ""

namespace :tapyrus do
  desc "walletを生成する"
  task :createwallet => :environment do |task, args|
    faucet = Glueby::Wallet.create
    puts "created new wallet: #{faucet.id}"
  end

  desc "FAUCETからsenderに資金を引き出す"
  task :faucet => :environment do |task, args|
    payment(FAUCET_ID, SENDER_ID, 1_000_000_000) # 10TPC引き出す
  end

  desc "TPCを送金する"
  task :payment => :environment do |task, args|
    payment(SENDER_ID, RECEIVER_ID, 10_000_000) # 0.1TPC引き出す
  end

  desc "ブロックを生成する"
  task :generate => :environment do |task, args|
    count = 1 # 生成するブロック数
    authority_key = "cUJN5RVzYWFoeY8rUztd47jzXCu1p57Ay8V7pqCzsBD3PEXN7Dd4" # minerの秘密鍵

    faucet = Glueby::Wallet.load(FAUCET_ID) # faucetのwalletをロード
    receive_address = faucet.internal_wallet.receive_address # mining報酬の受け取りアドレスを生成
    puts Glueby::Internal::RPC.client.generatetoaddress(count, receive_address, authority_key) # blockを生成(dev modeのみ有効なコマンド)

    puts "#{count} blocks generated. send reward to: #{receive_address}" # block生成数と報酬を受け取ったaddressを表示
    puts "after block=#{Glueby::Internal::RPC.client.getblockcount}" # 生成後のblockの高さを表示
  end


  #############################
  # ここからはutil系のtask
  #############################
  desc "ブロックカウントの確認"
  task :getblockcount => :environment do |task, args|
    puts Glueby::Internal::RPC.client.getblockcount
  end

  desc "faucetとsenderとreceiverの残高確認"
  task :getbalance => :environment do |task, args|
    faucet = Glueby::Wallet.load(FAUCET_ID)
    sender = Glueby::Wallet.load(SENDER_ID)
    receiver = Glueby::Wallet.load(RECEIVER_ID)
    puts "faucet balance=#{faucet.balances}"
    puts "sender balance=#{sender.balances}"
    puts "receiver balance=#{receiver.balances}"
  end

  desc "senderとreceiverのUTXOを確認"
  task :getutxocount => :environment do |task, args|
    sender = Glueby::Wallet.load(SENDER_ID)
    receiver = Glueby::Wallet.load(RECEIVER_ID)
    puts "sender utxo=#{sender.internal_wallet.list_unspent.size}"
    puts "receiver utxo=#{receiver.internal_wallet.list_unspent.size}"
  end

  # @description senderからreceiverにamountのTPCを送金する
  # @param sender_id 送信者のwallet_id
  # @param receiver_id 受信者のwallet_id
  # @param amount 送金するtapyrusの量
  def payment(sender_id, receiver_id, ammount)
    sender = Glueby::Wallet.load(sender_id)
    receiver = Glueby::Wallet.load(receiver_id)
    address = receiver.internal_wallet.receive_address
    puts "receiver address = #{address}"
    tx = Glueby::Contract::Payment.transfer(sender: sender,
                                            receiver_address: address,
                                            amount: ammount)
    puts "transaction.id = #{tx.txid}"
  end
end
