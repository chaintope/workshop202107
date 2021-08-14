# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2021_08_13_162620) do

  create_table "glueby_keys", force: :cascade do |t|
    t.string "private_key"
    t.string "public_key"
    t.string "script_pubkey"
    t.string "label"
    t.integer "purpose"
    t.integer "wallet_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["label"], name: "index_glueby_keys_on_label"
    t.index ["private_key"], name: "index_glueby_keys_on_private_key", unique: true
    t.index ["script_pubkey"], name: "index_glueby_keys_on_script_pubkey", unique: true
    t.index ["wallet_id"], name: "index_glueby_keys_on_wallet_id"
  end

  create_table "glueby_system_informations", force: :cascade do |t|
    t.string "info_key"
    t.string "info_value"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["info_key"], name: "index_glueby_system_informations_on_info_key", unique: true
  end

  create_table "glueby_timestamps", force: :cascade do |t|
    t.string "txid"
    t.integer "status"
    t.string "content_hash"
    t.string "prefix"
    t.string "wallet_id"
  end

  create_table "glueby_utxos", force: :cascade do |t|
    t.string "txid"
    t.integer "index"
    t.bigint "value"
    t.string "script_pubkey"
    t.string "label"
    t.integer "status"
    t.integer "key_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["key_id"], name: "index_glueby_utxos_on_key_id"
    t.index ["label"], name: "index_glueby_utxos_on_label"
    t.index ["txid", "index"], name: "index_glueby_utxos_on_txid_and_index", unique: true
  end

  create_table "glueby_wallets", force: :cascade do |t|
    t.string "wallet_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["wallet_id"], name: "index_glueby_wallets_on_wallet_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "wallet_id", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

end
