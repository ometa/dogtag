class AddPostalCodeToPeople < ActiveRecord::Migration
  def up
    add_column :people, :postal_code, :string, null: false, default: ''
  end

  def down
    remove_column :people, :postal_code
  end
end
