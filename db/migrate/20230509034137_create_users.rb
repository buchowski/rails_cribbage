class CreateUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :users do |t|
      t.string :password_digest
      t.boolean :is_admin
      t.string :name, limit: 20
      t.string :email, limit: 24

      t.timestamps
    end
  end
end
