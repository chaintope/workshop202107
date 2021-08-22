module GluebyHelper

  RECEIVE_ADDRESS_LABEL = 'receive'

  def current_receive_address(wallet)
    # TODO: Third: Implement load address. The address register by `receive` label.
    # Addresses order from oldest. So latest address is bottom of list.
    #
    # like this: wallet.internal_wallet.get_addresses("same-label")[-1]
  end

  # ブロックを生成する
  def generate_block(wallet)
    count = 1 # 生成するブロック数
    authority_key = "cUJN5RVzYWFoeY8rUztd47jzXCu1p57Ay8V7pqCzsBD3PEXN7Dd4" # minerの秘密鍵

    # TODO: Fourth: Implement generate block.
    # It can generate block from the `generatetoaddress` command of JSON-RPC in Tapyrus.
    # So please call that JSON-RPC using by `Glueby::Internal::RPC.client`.
    #
    # like this:
    #   Glueby::Internal::RPC.client
    #     .generatetoaddress(count, receive_address, authority_key) # blockを生成(dev modeのみ有効なコマンド)
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
