class Recommendation < ActiveRecord::Base
  attr_accessible :exercise_id, :recommended_user_id, :result_id, :times_accepted, :type, :user_id
  belongs_to :exercise
  belongs_to :result
  has_many :users
end
