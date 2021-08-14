class Payment
  include ActiveModel::Model
  attr_accessor :address, :amount

  validates :address, presence: true
  validates :amount, presence: true
  validate :address_format

  # 送金を実行
  def transfer(wallet)
    Glueby::Contract::Payment.transfer(sender: wallet,
                                       receiver_address: self.address,
                                       amount: self.amount.to_i * 100_000_000) # convert unit TPC to tapyrus
  end

  # 送信先のアドレスをチェック
  def address_format
    unless self.address.blank?
      begin
        Tapyrus::Script.parse_from_addr(self.address)
      rescue Exception => e
        errors.add(:address, e.message)
      end
    end
  end
end