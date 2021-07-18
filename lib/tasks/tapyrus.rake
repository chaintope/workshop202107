### *How to use this
# 1. `bundle exec rails tapyrus:createwallet` を3回実行する
# 2. 生成されたwallet_idをこのファイルのFAUCET_ID, SENDER_ID, RECEIVER_IDに指定する
# 3. `bundle exec rails tapyrus:generate` を実行してブロックを生成
# 4. `bundle exec rails tapyrus:faucet` を実行してfaucetからTCPを引き出す
# 5. `bundle exec rails tapyrus:generate` を実行して 4.のtransactionを確定させる
# 6. `bundle exec rails tapyrus:payment` を実行してsenderからreceiverにTCPを送金する
# 7. `bundle exec rails tapyrus_generate` を実行して6. のtransactionを確定させる
########################################

# faucetのwallet_id。mining報酬が溜まっていくwallet。
FAUCET_ID = ""
# サンプルで使うsender & aliceのwallet_id。TCPを持っている必要があるのでfaucetと同じwallet_idを指定している。
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

  desc "TCPを送金する"
  task :payment => :environment do |task, args|
    payment(SENDER_ID, RECEIVER_ID, 10_000_000) # 0.1TPC引き出す
  end

  desc "ブロックを生成する"
  task :generate, ["count"] => :environment do |task, args|
    count = args["count"].to_i
    count = 1 if count == 0
    authority_key = "c87509a1c067bbde78beb793e6fa76530b6382a4c0241e5e4a9ec0a0f44dc0d3"

    puts "before block=#{Glueby::Internal::RPC.client.getblockcount}"
    Glueby::Internal::RPC.perform_as("wallet-"+FAUCET_ID) do |client|
      client.generate(count, authority_key)
    end
    puts "#{count} blocks generated."
    puts "after block=#{Glueby::Internal::RPC.client.getblockcount}"
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

  # @description senderからreceiverにamountのTCPを送金する
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
