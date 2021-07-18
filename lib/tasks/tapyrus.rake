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
    # 1st implement this.
  end

  desc "ブロックを生成する"
  task :generate => :environment do |task, args|
    # 2nd implement this
  end

  desc "FAUCETからsenderに資金を引き出す"
  task :faucet => :environment do |task, args|
    # 3rd implement this
  end

  desc "TCPを送金する"
  task :payment => :environment do |task, args|
    # 4th implement this
  end

  #############################
  # ここからはutil系のtask
  #############################
  desc "faucetとsenderとreceiverの残高確認"
  task :getbalance => :environment do |task, args|
    # 5th implement this
  end

  desc "senderとreceiverのUTXOを確認"
  task :getutxocount => :environment do |task, args|
    # 6th implement this
  end
end
