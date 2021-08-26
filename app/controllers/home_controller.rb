class HomeController < ApplicationController
  include GluebyHelper

  before_action :authenticate_user!
  before_action :load_wallet

  def index
    @utxos = []

    if @wallet
      @receive_address = current_receive_address(@wallet)
      @utxos = @wallet.internal_wallet.list_unspent(false)
    end

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
    begin
      generate_block(@wallet)
      sync_block

      flash[:success] = 'Successfully generate block'
    rescue Tapyrus::RPC::Error => e
      Rails.logger.warn e.backtrace.join("\n")
      flash[:error] = e.message
    end
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
    unless current_user.wallet_id.empty?
      @wallet = Glueby::Wallet.load(current_user.wallet_id)
    end
  end

end
