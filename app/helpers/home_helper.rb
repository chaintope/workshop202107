module HomeHelper
  # TPCの残高を返す
  def tpcbalance
    if @wallet
      return @wallet.balances[""].to_i / 100_000_000.to_f
    else
      return "NaN"
    end
  end
end
