class TimestampController < ApplicationController
  include GluebyHelper

  before_action :authenticate_user!
  before_action :load_wallet

  # timestampのTOPページ表示
  def index
    @list = Timestamp.list
  end

  # 任意のメッセージの存在証明をBCに記録するアクション
  def register
    timestamp = Timestamp.new(timestamp_params)

    if timestamp.valid?
      begin
        tx = timestamp.register(@wallet)
        flash[:notice] = "Create new timestamp #{tx.txid}"
      rescue Glueby::Contract::Errors::InsufficientFunds => e
        flash[:error] = "手数料が不足しています。"
      rescue Exception => e
        flash[:error] = e.message
        Rails.logger.warn e
      end
    else
      flash[:error] = timestamp.errors.full_messages
    end

    redirect_to action: :index
  end

  # 任意のメッセージの存在証明をBCに記録するアクション
  def verify
    verifier = Verifier.new(verify_params)

    if verifier.valid? && verifier.verify_all?(@wallet)
      flash[:success] = "検証が成功しました。指定されたMessageが記録されています。"
    else
      flash[:error] = verifier.errors.full_messages
    end

    redirect_to action: :index
  end


  private

  def timestamp_params
    params.require(:timestamp).permit(:message)
  end

  def verify_params
    params.require(:verify).permit(:txid, :message)
  end

  def load_wallet
    @wallet = Glueby::Wallet.load(current_user.wallet_id)
  end

end
