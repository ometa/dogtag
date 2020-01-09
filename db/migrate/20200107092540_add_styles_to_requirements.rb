class AddStylesToRequirements < ActiveRecord::Migration
  def up
    add_column :requirements, :style_ids, :string
    backfill_style_ids
    change_column_null :requirements, :style_ids, false
  end

  def down
    remove_column :requirements, :style_ids
  end

  private

  def backfill_style_ids
    execute <<-SQL
      UPDATE requirements
      SET style_ids = 'racing'
    SQL
  end
end
