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
  def self.recomendation_test(exercise_id)
    @find = Result.where("exercise_id = ?", exercise_id).order("grade DESC", :duration)
    @find_user = User.find(@find[0].user_id)
    {testG: @find[0].grade,
    testD: @find[0].duration,
    testID: @find[0].id, 
    testEID: @find[0].exercise_id,
    testUID: @find[0].user_id,
    testUName: @find_user.first_name,
    testULastName: @find_user.last_name }
  end

  private

  def total_choices
    @total_choices ||= choices.length
  end


end
