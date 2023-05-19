class ChangePlayerIdsToIntegers < ActiveRecord::Migration[7.0]
  def change
    change_column :games, :player_one_id, :integer
    change_column :games, :player_two_id, :integer
  end
end
