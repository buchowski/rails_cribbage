class ChangeColumnNullToUsers < ActiveRecord::Migration[7.0]
  def up
    change_column_null :users, :encrypted_password, false, BCrypt::Password.create("secret")
    change_column_null :users, :email, false, "nature_boy@ric.xyz"
  end

  def down
    change_column_null :users, :encrypted_password, true
    change_column_null :users, :email, true
  end
end
