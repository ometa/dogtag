class ChangeRegStrsToTexts < ActiveRecord::Migration
  def change

    def up
      change_column :registrations, :description, :text
    end

    def down
      # This might cause trouble if you have strings longer
      # than 255 characters.
      change_column :registrations, :description, :string
    end

  end
end
