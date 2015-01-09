class AddPostalCodeToUsers < ActiveRecord::Migration
  def up
    add_column :users, :postal_code, :string, null: false, default: ''
  end

  def down
    remove_column :users, :postal_code
  end
end
