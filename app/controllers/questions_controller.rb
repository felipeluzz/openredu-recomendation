# -*- encoding : utf-8 -*-
class QuestionsController < BaseController
  before_filter :load_hierarchy

  authorize_resource :question

  def show
    @first_question = @question.first_item
    @last_question = @question.last_item
    @choice = @question.choices.
      first(:conditions => { :user_id => current_user.id}) || @question.choices.build
    @result = @exercise.result_for(current_user)
    @can_manage_lecture = can?(:manage, @lecture)
    @review = !@result.nil? || @can_manage_lecture

    #--------------------------------------------------------------------------------
    #Amigos recomendados
    @friend1_firstName, @friend1_lastName, @friend1_login, @friend2_firstName, @friend2_lastName, @friend2_login, @friend3_firstName, @friend3_lastName, @friend3_login = Result.recommendation_friends(current_user.id, @lecture.lectureable)
    if @friend1_firstName.nil?
      @no_friend = true
    else
      @no_friend = false
      @friend1_name = "#{@friend1_firstName} #{@friend1_lastName}"
      @friend1_URL = "#{request.domain}/pessoas/#{@friend1_login}"
      if not @friend2_firstName.nil?
        @has_two_friends = true
        @friend2_name = "#{@friend2_firstName} #{@friend2_lastName}"
        @friend2_URL = "#{request.domain}/pessoas/#{@friend2_login}"
        if not @friend3_firstName.nil?
          @has_three_friends = true
          @friend3_name = "#{@friend3_firstName} #{@friend3_lastName}"
          @friend3_URL = "#{request.domain}/pessoas/#{@friend3_login}"
        else
          @has_three_friends = false
        end
      else
        @has_two_friends = false
        @has_three_friends = false
      end
    end
    #Outros recomendados
    @ranking_user1_firstName, @ranking_user1_lastName, @ranking_user1_login, @ranking_user2_firstName, @ranking_user2_lastName, @ranking_user2_login, @ranking_user3_firstName, @ranking_user3_lastName, @ranking_user3_login = Result.recomendation_ranking(@lecture.lectureable)
    if @ranking_user1_firstName.nil?
      @no_result = true
    else
      @no_result = false
      @ranking_user1_name = "#{@ranking_user1_firstName} #{@ranking_user1_lastName}"
      @ranking_user1_URL = "#{request.domain}/pessoas/#{@ranking_user1_login}"
      if not @ranking_user2_firstName.nil?
        @has_two_results = true
        @ranking_user2_name = "#{@ranking_user2_firstName} #{@ranking_user2_lastName}"
        @ranking_user2_URL = "#{request.domain}/pessoas/#{@ranking_user2_login}"
        if not @ranking_user3_firstName.nil?
          @has_three_results = true
          @ranking_user3_name = "#{@ranking_user3_firstName} #{@ranking_user3_lastName}"
          @ranking_user3_URL = "#{request.domain}/pessoas/#{@ranking_user3_login}"
        else
          @has_three_results = false
        end
      else
        @has_two_results = false
        @has_three_results = false
      end
    end
    #------------------------------------------------------

    if current_user.get_association_with(@lecture.subject)
      asset_report = @lecture.asset_reports.of_user(current_user).first
      @student_grade = asset_report.enrollment.grade.to_i
      @done = asset_report.done
    end

    respond_to do |format|
      format.html
    end
  end

  protected

  def load_hierarchy
    @question = Question.find(params[:id])
    @exercise = @question.exercise
    @lecture = @exercise.lecture
    @subject = @lecture.subject
    @space = @subject.space
    @course = @space.course
    @environment = @course.environment
  end
end
