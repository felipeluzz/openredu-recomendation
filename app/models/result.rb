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
    #Três melhores colocados
    @find_results = Result.where("exercise_id = ?", exercise_id).order("grade DESC", :duration)
    if not @find_results.blank?
      if @find_results[0].state == "finalized"
        @find_user1 = User.find(@find_results[0].user_id)
      else
        return nil
      end
      if not @find_results[1].nil? and @find_results[1].state == "finalized"
        @find_user2 = User.find(@find_results[1].user_id)
      else
        return @find_user1.first_name, @find_user1.last_name, @find_user1.login
      end
      if @find_results[2].state == "finalized"
        @find_user3 = User.find(@find_results[2].user_id)
        return @find_user1.first_name, @find_user1.last_name, @find_user1.login, @find_user2.first_name, @find_user2.last_name, @find_user2.login, @find_user3.first_name, @find_user3.last_name, @find_user3.login
      else
        return @find_user1.first_name, @find_user1.last_name, @find_user1.login, @find_user2.first_name, @find_user2.last_name, @find_user2.login
      end
    else
      return nil
    end
    # {
    #   ranking_user1_firstName: @find_user1.first_name,
    #   ranking_user1_lastName: @find_user1.last_name,
    #   ranking_username1: @find_user1.login,
    #   ranking_user2_firstName: @find_user2.first_name,
    #   ranking_user2_lastName: @find_user2.last_name,
    #   ranking_username2: @find_user2.login,
    #   ranking_user3_firstName: @find_user3.first_name,
    #   ranking_user3_lastName: @find_user3.last_name,
    #   ranking_username3: @find_user3.login
    # }
  end

  private

  def total_choices
    @total_choices ||= choices.length
  end


end
