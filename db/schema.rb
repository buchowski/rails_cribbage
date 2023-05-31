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

ActiveRecord::Schema[7.0].define(version: 2023_05_19_033055) do
  create_table "games", force: :cascade do |t|
    t.integer "player_one_id"
    t.integer "player_two_id"
    t.string "player_one_cards"
    t.string "player_two_cards"
    t.string "pile_cards"
    t.string "cut_card"
    t.integer "dealer_id"
    t.integer "whose_turn_id"
    t.string "current_fsm_state"
    t.integer "player_one_points"
    t.integer "player_two_points"
    t.integer "round"
    t.integer "points_to_win"
    t.integer "winner_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "crib_cards"
  end

  create_table "users", force: :cascade do |t|
    t.string "password_digest"
    t.boolean "is_admin"
    t.string "name", limit: 20
    t.string "email", limit: 24
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
