class CreateRecommendations < ActiveRecord::Migration
  def change
    create_table :recommendations do |t|
      t.integer :user_id
      t.integer :exercise_id
      t.integer :result_id
      t.string :type
      t.integer :recommended_user_id
      t.integer :times_accepted

      t.timestamps
    end
  end
end
