class AddStylesToRequirements < ActiveRecord::Migration
  def up
    add_column :requirements, :style_ids, :string
    backfill_style_ids
    change_column_null :teams, :style, false
  end

  def down
    remove_column :requirements, :style_ids
  end

  private

  def backfill_style_ids
    execute <<-SQL
      INSERT INTO requirements (style_ids)
      VALUES ('racing')
    SQL
  end
end
