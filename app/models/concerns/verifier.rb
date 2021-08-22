class Verifier

  include ActiveModel::Model

  attr_accessor :txid
  attr_accessor :message
  validates :txid, presence: true
  validates :message, presence: true

  # @description タイムスタンプを検証する
  # @param wallet Glueby::Wallet タイムスタンプを発行したIssuerのwallet
  def verify_all?(wallet)
    begin
      tx = load_transaction(@txid)
      unless verify_message(tx)
        errors.add(:base, "検証失敗: Messageが一致しません。")
      end
      unless verify_issuer(tx, wallet)
        errors.add(:base, "検証失敗: 発行者が一致しません。")
      end

      errors.blank?
    rescue Tapyrus::RPC::Error => e
      Rails.logger.warn e.message
      Rails.logger.warn e.backtrace.join("\n")
      errors.add(:txid, "指定されたtxidのTimestampは記録されていません。")
      false
    rescue StandardError => e
      Rails.logger.warn e.message
      Rails.logger.warn e.backtrace.join("\n")
      errors.add(:base, e.message)
      false
    end
  end

  # @description タイムスタンプとして記録されたメッセージと一致するか検証する
  # @param tx Tapyrus::Tx タイムスタンプ Transaction
  def verify_message(tx)
    Tapyrus::sha256(@message).bth == timestamp_payload(tx)
  end

  # @description タイムスタンプの発行者と一致するか検証する
  # @param tx Tapyrus::Tx タイムスタンプ Transaction
  # @param wallet Glueby::Wallet 発行者のwallet
  def verify_issuer(tx, wallet)
    out_point = tx.inputs[0].out_point
    input_tx = load_transaction(out_point.txid)
    output = input_tx.outputs[out_point.index]

    key = Glueby::Internal::Wallet::AR::Key.key_for_output(output)
    key.wallet.wallet_id == wallet.id
  end

  # @description タイムスタンプtxから刻まれたコンテンツのhash値を取得する
  # @txid Tapyrus::Tx タイムスタンプ Transaction
  def timestamp_payload(tx)
    tx.outputs[0].script_pubkey.op_return_data.bth
  end

  # @description Tapyrus-nodeからtxidのTransactionを取得する
  # @txid 取得するtransaction id
  def load_transaction(txid)
    tx_payload = Glueby::Internal::RPC.client.getrawtransaction(txid, 0)
    Tapyrus::Tx.parse_from_payload(tx_payload.htb)
  end

end