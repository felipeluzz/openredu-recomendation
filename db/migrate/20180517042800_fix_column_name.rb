class FixColumnName < ActiveRecord::Migration
  def up
    rename_column :recommendations, :type, :recommendation_type
  end

  def down
  end
end
