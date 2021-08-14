class HomeController < ApplicationController
  include GluebyHelper

  before_action :authenticate_user!
  before_action :load_wallet

  RECEIVE_ADDRESS_LABEL = 'receive'
  def index
    addrs = @wallet.internal_wallet.get_addresses(RECEIVE_ADDRESS_LABEL)
    @receive_address = addrs[-1]
    @utxos = @wallet.internal_wallet.list_unspent(false)
    @block_height = Glueby::Internal::RPC.client.getblockcount
    @sync_block = Glueby::AR::SystemInformation.synced_block_height.int_value
  end

  # 新しい受け取りアドレスを生成する
  def create_receive_address
    @wallet.internal_wallet.receive_address(RECEIVE_ADDRESS_LABEL)

    flash[:notice] = 'Create new receive address'
    redirect_to action: :index
  end

  # ブロックを生成する
  def generate
    count = 1 # 生成するブロック数
    authority_key = "cUJN5RVzYWFoeY8rUztd47jzXCu1p57Ay8V7pqCzsBD3PEXN7Dd4" # minerの秘密鍵

    receive_address = current_receive_address # mining報酬の受け取りアドレス
    Glueby::Internal::RPC.client.generatetoaddress(count, receive_address, authority_key) # blockを生成(dev modeのみ有効なコマンド)
    sync_block # block情報をDBに同期

    flash[:success] = 'Successfully generate block'
    redirect_to action: :index
  end

  # TPCを送金する
  def payment

    payment = Payment.new(payment_params)
    unless payment.valid?
      flash[:error] =  payment.errors.full_messages
    end

    begin
      payment.transfer(@wallet)
      flash[:success] = "Successfully Send TPC."
    rescue Exception => e
      flash[:error] = e.message
      Rails.logger.warn e
    end

    redirect_to action: :index
  end

  private

  def payment_params
    params.require(:payment).permit(:address, :amount)
  end

  def load_wallet
    @wallet = Glueby::Wallet.load(current_user.wallet_id)
  end

  def current_receive_address
    @wallet.internal_wallet.get_addresses(RECEIVE_ADDRESS_LABEL)[-1]
  end

end
