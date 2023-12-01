class CreateUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :users, id: :serial do |t|
      t.string :password_digest
      t.boolean :is_admin, default: false
      t.boolean :is_bot, default: false
      t.string :name, limit: 20
      t.text :email, limit: 24

      t.timestamps
    end
  end
end
