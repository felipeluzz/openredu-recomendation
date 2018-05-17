class RemoveResultIdFromRecommendations < ActiveRecord::Migration
  def up
    remove_column :recommendations, :result_id
  end

  def down
  end
end
