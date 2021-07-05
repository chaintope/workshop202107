# faucetのwallet_id。mining報酬が溜まっていくwallet。
FAUCET_ID = "73f92ba5dc959f4576a39f13566428dd"

# サンプルで使うsender & aliceのwallet_id。TCPを持っている必要があるのでfaucetと同じwallet_idを指定している。
SENDER_ID = "73f92ba5dc959f4576a39f13566428dd"
# サンプルで使うreceiver & bobのwallet_id。
RECEIVER_ID = "7c7ae149b6e819802e93e672a96168ed"

namespace :tapyrus do
  desc "walletを生成する"
  task :create_wallet => :environment do |task, args|
    faucet = Glueby::Wallet.create
    puts "created new wallet: #{faucet.id}"
  end

  desc "TCPを送金する"
  task :payment => :environment do |task, args|
    sender = Glueby::Wallet.load(SENDER_ID)
    receiver = Glueby::Wallet.load(RECEIVER_ID)
    address = receiver.internal_wallet.receive_address
    puts "receiver address = #{address}"
    tx = Glueby::Contract::Payment.transfer(sender: sender,
                                       receiver_address: address,
                                       amount: 10_000_000)
    puts "transaction.id = #{tx.tx_hash}"
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

  desc "senderとreceiverの残高確認"
  task :getbalance => :environment do |task, args|
    sender = Glueby::Wallet.load(SENDER_ID)
    receiver = Glueby::Wallet.load(RECEIVER_ID)
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
end
