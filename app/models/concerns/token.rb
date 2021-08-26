class Token
  include ActiveModel::Model, TokenHelper

  attr_accessor :token_type, :amount

  validates :token_type, presence: true
  validates :amount, presence: true, if: -> {@token_type.to_i != Tapyrus::Color::TokenTypes::NFT}

  # tokenを発行
  def issue(wallet)
    @amount ||= 1
    tokens = Glueby::Contract::Token.issue!(issuer: wallet, token_type: @token_type.to_i, amount: @amount.to_i)
    token_info = tokens[0]
    token_id = token_info.color_id.payload.bth
    token_type = color_type2name(token_info.token_type)

    {id: token_id, token_type: token_type}
  end

end