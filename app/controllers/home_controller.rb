class HomeController < ApplicationController
  before_action :authenticate_user!
  before_action :load_wallet

  RECEIVE_ADDRESS_LABEL = 'receive'
  def index
    addrs = @wallet.internal_wallet.get_addresses(RECEIVE_ADDRESS_LABEL)
    @receive_address = addrs[-1]
    @utxos = @wallet.internal_wallet.list_unspent(false)

  end

  def create_receive_address
    @wallet.internal_wallet.receive_address(RECEIVE_ADDRESS_LABEL)
    redirect_to action: :index
  end

  private

  def load_wallet
    @wallet = Glueby::Wallet.load(current_user.wallet_id)
  end
end
