class CreateGames < ActiveRecord::Migration[7.0]
  def change
    create_table :games, id: :serial do |t|
      t.serial :player_one_id
      t.integer :player_two_id, null: true
      t.json :player_one_cards
      t.json :player_two_cards
      t.string :pile_cards, array: true
      t.string :crib_cards, array: true
      t.string :cut_card
      t.integer :dealer_id, null: true
      t.integer :whose_turn_id, null: true
      t.string :current_fsm_state
      t.integer :player_one_points
      t.integer :player_two_points
      t.integer :round
      t.integer :points_to_win
      t.integer :winner_id, null: true

      t.timestamps
    end
  end
end
