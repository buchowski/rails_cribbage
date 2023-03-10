class CreateGames < ActiveRecord::Migration[7.0]
  def change
    create_table :games do |t|
      t.string :player_one_id
      t.string :player_two_id
      t.string :player_one_cards
      t.string :player_two_cards
      t.string :pile_cards
      t.string :cut_card
      t.string :dealer_id
      t.string :whose_turn_id
      t.string :current_fsm_state
      t.integer :player_one_points
      t.integer :player_two_points
      t.integer :round
      t.integer :points_to_win
      t.string :winner_id

      t.timestamps
    end
  end
end
