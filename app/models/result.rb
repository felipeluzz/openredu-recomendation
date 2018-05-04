# -*- encoding : utf-8 -*-
class Result < ActiveRecord::Base
  include AASM

  belongs_to :exercise
  belongs_to :user
  has_many :choices, dependent: :destroy

  scope :n_recents, lambda { |n|
    order('finalized_at DESC').limit(n)
  }

  scope :n_best_grades, lambda { |n|
    order('grade DESC').limit(n)
  }

  aasm_column :state
  aasm_initial_state :waiting

  aasm_state :waiting
  aasm_state :started, enter: lambda { |r|
    r.update_attributes({started_at: Time.zone.now })
  }
  aasm_state :finalized, enter: lambda { |r|
    r.update_attributes({finalized_at: Time.zone.now})
    r.assign_dangling_choices
    r.update_attributes({ grade: r.calculate_grade,
                          duration: r.calculate_duration })
  }

  aasm_event :start do
    transitions to: :started, from: :waiting
  end

  aasm_event :finalize do
    transitions to: :finalized, from: :started
  end

  validates_uniqueness_of :user_id, scope: :exercise_id

  # Calcula noda baseada no número de acertos e peso por questão no exercício
  # associado
  def calculate_grade
    weight = exercise.nil? ? BigDecimal.new("0.0") : exercise.question_weight
    choices.correct.count * weight
  end

  # finalized_at - started_at caso o result esteja finalizado
  def calculate_duration
    if finalized_at && started_at
      return (finalized_at - started_at)
    else
      return 0
    end
  end

  def assign_dangling_choices
    choices << exercise.choices_for(user) if exercise
  end

  def to_report
    { hits: hits, misses: misses, blanks: blanks,
      duration: duration, grade: grade }
  end

  def misses
    total_choices - hits
  end

  def hits
    @hits ||= choices.select(&:correct).length
  end

  def blanks
    return 0 unless exercise
    exercise.questions.length - total_choices
  end

  #Teste para recomendação
  def self.recomendation_ranking(exercise_id)
    @find_results = Result.where("exercise_id = ?", exercise_id).order("grade DESC", :duration)
    if not @find_results.blank?
      if @find_results[0].state == "finalized"
        @find_user = User.find(@find_results[0].user_id)
        {ranking_grade: @find_results[0].grade,
        ranking_duration: @find_results[0].duration,
        ranking_ID: @find_results[0].id, 
        ranking_exerciseID: @find_results[0].exercise_id,
        ranking_userID: @find_results[0].user_id,
        ranking_user_firstName: @find_user.first_name,
        ranking_user_lastName: @find_user.last_name,
        ranking_username: @find_user.login, 
        ranking_state: @find_results[0].state}
      end
    end
  end

  private

  def total_choices
    @total_choices ||= choices.length
  end


end
