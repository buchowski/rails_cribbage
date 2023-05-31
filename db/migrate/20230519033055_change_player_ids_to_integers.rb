class ChangePlayerIdsToIntegers < ActiveRecord::Migration[7.0]
  def up
    change_column :games, :player_one_id, :integer
    change_column :games, :player_two_id, :integer
    change_column :games, :dealer_id, :integer
    change_column :games, :whose_turn_id, :integer
    change_column :games, :winner_id, :integer
  end
  def down
    change_column :games, :player_one_id, :string
    change_column :games, :player_two_id, :string
    change_column :games, :dealer_id, :string
    change_column :games, :whose_turn_id, :string
    change_column :games, :winner_id, :string
  end
end
