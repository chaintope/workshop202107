module GluebyHelper

  RECEIVE_ADDRESS_LABEL = 'receive'

  def current_receive_address(wallet)
    wallet.internal_wallet.get_addresses(RECEIVE_ADDRESS_LABEL)[-1]
  end

  # ブロックを生成する
  def generate_block(wallet)
    count = 1 # 生成するブロック数
    authority_key = "cUJN5RVzYWFoeY8rUztd47jzXCu1p57Ay8V7pqCzsBD3PEXN7Dd4" # minerの秘密鍵

    Glueby::Internal::RPC.client.generatetoaddress(count, current_receive_address(wallet), authority_key) # blockを生成(dev modeのみ有効なコマンド)
  end

  # copy from Glueby::Contract::Task::BlockSyncer
  def sync_block

    latest_block_num = Glueby::Internal::RPC.client.getblockcount
    synced_block = Glueby::AR::SystemInformation.synced_block_height
    (synced_block.int_value + 1..latest_block_num).each do |height|
      ::ActiveRecord::Base.transaction do
        Glueby::BlockSyncer.new(height).run
        synced_block.update(info_value: height.to_s)
      end
      puts "success in synchronization (block height=#{height})"
    end

  end

end
