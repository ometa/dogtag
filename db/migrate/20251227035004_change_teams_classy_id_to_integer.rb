class ChangeTeamsClassyIdToInteger < ActiveRecord::Migration[7.0]
  def up
    # Convert string classy_id to integer
    # PostgreSQL USING clause handles the conversion of existing string data
    # NULL values remain NULL, empty strings become NULL
    execute <<-SQL
      UPDATE teams SET classy_id = NULL WHERE classy_id = '';
    SQL

    change_column :teams, :classy_id, :integer, using: 'classy_id::integer'
  end

  def down
    change_column :teams, :classy_id, :string
  end
end
