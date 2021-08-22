class Timestamp
  include ActiveModel::Model

  attr_accessor :message
  validates :message, presence: true

  # 自分が発行したtimestampのtx listを取得する
  def self.list
    Glueby::Contract::AR::Timestamp.all
  end

  # timestampを記録する
  def register(wallet)
    timestamp = Glueby::Contract::Timestamp.new(wallet: wallet, content: self.message)
    # save in active record
    ar_t = Glueby::Contract::AR::Timestamp.new(wallet_id: wallet.id, content: self.message)
    tx = timestamp.save!
    ar_t.txid = tx.txid
    ar_t.save!
    ar_t.unconfirmed! # statusをunconfirmedに更新

    tx
  end
end