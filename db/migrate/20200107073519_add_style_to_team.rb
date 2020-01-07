class AddStyleToTeam < ActiveRecord::Migration
  def up
    add_column :teams, :style, :integer, default: 0
    backfill_style
    change_column_null :teams, :style, false
  end

  def down
    remove_column :teams, :style
  end

  private

  def backfill_style
    execute <<-SQL
      INSERT INTO teams (style)
      VALUES (0)
    SQL
  end
end
