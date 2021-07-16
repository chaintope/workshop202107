### *How to use this
# How to setup.
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

  ##### Payment 関連 #####
  #######################
  desc "walletを生成する"
  task :createwallet => :environment do |task, args|
    faucet = Glueby::Wallet.create
    puts "created new wallet: #{faucet.id}"
  end

  desc "ブロックを生成する"
  task :generate, ["count"] => :environment do |task, args|
    count = args["count"].to_i
    count = 1 if count == 0
    authority_key = "cUJN5RVzYWFoeY8rUztd47jzXCu1p57Ay8V7pqCzsBD3PEXN7Dd4"

    faucet = Glueby::Wallet.load(FAUCET_ID)
    puts "before block=#{Glueby::Internal::RPC.client.getblockcount}"
    receive_address = faucet.internal_wallet.receive_address
    puts Glueby::Internal::RPC.client.generatetoaddress(1, receive_address, authority_key)
    # Glueby::Internal::RPC.perform_as("wallet-"+FAUCET_ID) do |client|
    #   client.generate(count, authority_key)
    # end
    puts "#{count} blocks generated."
    puts "after block=#{Glueby::Internal::RPC.client.getblockcount}"

    # 生成されたblockの情報をDBに取り込む必要があるので、generate後にglueby:contract:block_syncer:startも実行する
    Rake::Task['glueby:contract:block_syncer:start'].execute()
  end


  desc "FAUCETからsenderに資金を引き出す"
  task :faucet => :environment do |task, args|
    payment(FAUCET_ID, SENDER_ID, 1_000_000_000) # 10TPC引き出す
  end

  desc "TCPを送金する"
  task :payment => :environment do |task, args|
    payment(SENDER_ID, RECEIVER_ID, 10_000_000) # 0.1TPCをreceiverに送金する。
  end

  ##### Timestamp 関連 #####
  #########################
  desc "任意のデータをTapyrusに記録する"
  task :timestamp, ["content"] => :environment do |task, args|
    sender = Glueby::Wallet.load(SENDER_ID)
    content = args['content'].to_s

    timestamp = Glueby::Contract::Timestamp.new(wallet: sender, content: content)
    tx = timestamp.save!
    puts "transaction.id = #{tx.txid}"
  end

  desc "指定されたデータが存在しているか確認する"
  task :verifytimestamp, ["txid", "content"] => :environment do |task, args|
    sender = Glueby::Wallet.load(SENDER_ID)
    txid = args['txid'].to_s
    content = args['content'].to_s

    puts "verify result = #{Tapyrus::sha256(content).bth == timestamp_payload(txid)}"
  end

  ##### Token(=Colored Coin) 関連 #####
  #########################
  desc "tokenを発行する"
  task :issuetoken => :environment do |task, args|
    alice = Glueby::Wallet.load(SENDER_ID)
    tokens = Glueby::Contract::Token.issue!(issuer: alice, amount: 100)
    token_info = tokens[0]
    txs = tokens[1]
    token_id = token_info.color_id.payload.bth
    token_type = color_type2name(token_info.token_type)
    puts "issue token: id=#{token_id}, type=#{token_type}"
    txs.each do |tx|
      puts tx.txid
    end
  end

  desc "tokenを再発行する"
  task :reissuetoken, ["color_id"] => :environment do |task, args|
    sender = Glueby::Wallet.load(SENDER_ID)
    color_id_hash = args["color_id"].to_s
    color_id = Tapyrus::Color::ColorIdentifier.parse_from_payload(color_id_hash.htb)
    token = Glueby::Contract::Token.new(color_id: color_id)
    (color_id_result, tx) = token.reissue!(issuer: sender, amount: 100)
    puts "reissue tx=#{tx.txid}"
  end

  desc "tokenを発行する(non-reissuable)"
  task :issuefixtoken => :environment do |task, args|
    alice = Glueby::Wallet.load(SENDER_ID)
    tokens = Glueby::Contract::Token.issue!(issuer: alice,
                                            token_type: Tapyrus::Color::TokenTypes::NON_REISSUABLE,
                                            amount: 100)
    token_info = tokens[0]
    txs = tokens[1]
    token_id = token_info.color_id.payload.bth
    token_type = color_type2name(token_info.token_type)
    puts "issue token: id=#{token_id}, type=#{token_type}"
    txs.each do |tx|
      puts tx.txid
    end
  end

  desc "tokenを発行する(NFT)"
  task :issuenft => :environment do |task, args|
    alice = Glueby::Wallet.load(SENDER_ID)
    tokens = Glueby::Contract::Token.issue!(issuer: alice,
                                            token_type: Tapyrus::Color::TokenTypes::NFT,
                                            amount: 100)
    token_info = tokens[0]
    txs = tokens[1]
    token_id = token_info.color_id.payload.bth
    token_type = color_type2name(token_info.token_type)
    puts "issue token: id=#{token_id}, type=#{token_type}"
    txs.each do |tx|
      puts tx.txid
    end
  end

  desc "tokenを送る"
  task :transfertoken, ["color_id"] => :environment do |task, args|
    alice = Glueby::Wallet.load(SENDER_ID)
    bob = Glueby::Wallet.load(RECEIVER_ID)

    color_id_hash = args["color_id"].to_s
    color_id = Tapyrus::Color::ColorIdentifier.parse_from_payload(color_id_hash.htb)
    token = Glueby::Contract::Token.new(color_id: color_id)
    address = bob.internal_wallet.receive_address

    amount = 50
    if(color_type2name(color_id.type) == "nft")
      amount = 1
    end
    (color_id_result, tx) = token.transfer!(sender: alice, receiver_address: address, amount: amount)
    puts "transfer tx=#{tx.txid}"
  end

  desc "tokenを燃やす"
  task :burntoken, ["color_id"] => :environment do |task, args|
    alice = Glueby::Wallet.load(SENDER_ID)

    color_id_hash = args["color_id"].to_s
    color_id = Tapyrus::Color::ColorIdentifier.parse_from_payload(color_id_hash.htb)
    token = Glueby::Contract::Token.new(color_id: color_id)

    amount = 10
    if(color_type2name(color_id.type) == "nft")
      amount = 1
    end
    tx = token.burn!(sender: alice, amount: amount)
    puts "transfer tx=#{tx.txid}"
  end

  desc "tokenの情報を表示する"
  task :tokeninfo, ["color_id"] => :environment do |task, args|
    color_id_hash = args["color_id"].to_s
    color_id = Tapyrus::Color::ColorIdentifier.parse_from_payload(color_id_hash.htb)
    token_id = color_id.payload.bth
    token_type = color_type2name(color_id.type)
    puts "token info: id=#{token_id}, type=#{token_type}"
  end


  #############################
  # ここからはutil系のtask
  #############################
  desc "ブロックカウントの確認"
  task :getblockcount => :environment do |task, args|
    puts Glueby::Internal::RPC.client.getblockcount
  end

  desc "transaction詳細を表示"
  task :getrawtx,["txid"] => :environment do |task, args|
    txid = args["txid"].to_s
    puts Glueby::Internal::RPC.client.getrawtransaction(txid, 1)
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

  desc "walletの一覧を取得"
  task :listwallets => :environment do |task, args|
    puts "wallets=#{Glueby::Internal::Wallet.wallets}"
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

  # @description タイムスタンプtxから刻まれたコンテンツのhash値を取得する
  # @txid 対象のtransaction id
  def timestamp_payload(txid)
    tx_payload = Glueby::Internal::RPC.client.getrawtransaction(txid, 0)
    tx = Tapyrus::Tx.parse_from_payload(tx_payload.htb)
    tx.outputs[0].script_pubkey.op_return_data.bth
  end

  # @description tokenの種類IDを名前に変換する
  # @param color_type tokenの種類ID
  def color_type2name(color_type)
    case color_type
    when Tapyrus::Color::TokenTypes::REISSUABLE
      "reissuable"
    when Tapyrus::Color::TokenTypes::NON_REISSUABLE
      "non_reissuable"
    when Tapyrus::Color::TokenTypes::NFT
      "nft"
    else
      "uncolored"
    end
  end
end
