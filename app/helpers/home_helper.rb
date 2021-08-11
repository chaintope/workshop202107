module HomeHelper
  # TPCの残高を返す
  def tpcbalance(wallet_id)
    unless wallet_id
      return "NaN"
    end

    return Glueby::Wallet.load(wallet_id).balances[""] / 100_000_000.to_f
  end
end
