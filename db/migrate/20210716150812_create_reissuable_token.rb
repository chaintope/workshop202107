class CreateReissuableToken < ActiveRecord::Migration[6.1]
  def change
    create_table :glueby_reissuable_tokens do |t|
      t.string  :color_id, null: false
      t.string  :script_pubkey, null: false
      t.timestamps
    end
    add_index :glueby_reissuable_tokens, [:color_id], unique: true
  end
end