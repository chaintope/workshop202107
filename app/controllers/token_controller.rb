class TokenController < ApplicationController
  include GluebyHelper, TokenHelper

  before_action :authenticate_user!
  before_action :load_wallet

  def index
    @list = @wallet.balances.select {|k,_| !k.blank?;} # TPC以外を表示
    @color_ids = @list.map {|k, _| k}
  end

  # Tokenを発行する
  def issue
    puts issue_params
    token = Token.new(issue_params)

    if token.valid?
      begin
        info = token.issue(@wallet)
        flash[:success] = "Successfully Issue Token. id=#{info[:id]}, type=#{info[:token_type]}"
      rescue Glueby::Contract::Errors::InsufficientFunds => e
        flash[:error] = "手数料が不足しています。"
      rescue Exception => e
        flash[:error] = e.message
        Rails.logger.warn e
      end
    else
      flash[:error] = token.errors.full_messages
    end

    redirect_to action: :index
  end

  # tokenを送る
  def send_token
    # TODO: Implement me
    flash[:error] = "Please implement me"
    redirect_to action: :index
  end
  private

  def issue_params
    params.require(:issue).permit(:token_type, :amount)
  end

  def load_wallet
    unless current_user.wallet_id.empty?
      @wallet = Glueby::Wallet.load(current_user.wallet_id)
    end
  end
end
