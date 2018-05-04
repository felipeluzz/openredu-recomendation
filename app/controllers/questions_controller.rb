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

    #Variáveis de recomendação
    @ranking = Result.recomendation_ranking(@lecture.lectureable)
    if not @ranking.nil?
      @no_result = false
      @ranking_grade = @ranking[:ranking_grade]
      @ranking_duration = @ranking[:ranking_duration]
      @ranking_ID = @ranking[:ranking_ID]
      @ranking_exerciseID = @ranking[:ranking_exerciseID]
      @ranking_userID = @ranking[:ranking_userID]
      @ranking_user_name = "#{@ranking[:ranking_user_firstName]} #{@ranking[:ranking_user_lastName]}"
      @ranking_username = @ranking[:ranking_username]
      @ranking_user_URL = "#{request.domain}/pessoas/#{@ranking_username}"
      @ranking_state = @ranking[:ranking_state]
    else
      @no_result = true
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
