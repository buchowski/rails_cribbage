class AddCribCardsToGame < ActiveRecord::Migration[7.0]
  def change
    add_column :games, :crib_cards, :string
  end
end
