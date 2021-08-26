module TokenHelper

  def color_id2rgb(color_id_hash)
    color_id_hash[2, 6]
  end

  # @description color_idをtoken_type名に変換する
  # @param color_id_hash color_idのhash表現
  def color_id2token_type(color_id_hash)
    color_id = Tapyrus::Color::ColorIdentifier.parse_from_payload(color_id_hash.htb)
    color_type2name(color_id.type)
  end

  # @description tokenの種類IDを名前に変換する
  # @param color_type tokenの種類ID
  def color_type2name(color_type)
    case color_type
    when Tapyrus::Color::TokenTypes::REISSUABLE
      "reissuable"
    when Tapyrus::Color::TokenTypes::NON_REISSUABLE
      "non_reissuable"
    when Tapyrus::Color::TokenTypes::NFT
      "NFT"
    else
      "uncolored"
    end
  end

  def token_type_options
    [["reissuable", Tapyrus::Color::TokenTypes::REISSUABLE], ["non_reissuable", Tapyrus::Color::TokenTypes::NON_REISSUABLE], ["NFT", Tapyrus::Color::TokenTypes::NFT]]
  end
end
