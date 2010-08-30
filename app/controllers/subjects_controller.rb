class SubjectsController < BaseController

  layout 'new_application'

  before_filter :login_required

  def index
    session[:subject_step] = session[:subject_params]= session[:subject_aulas]= session[:subject_id] = nil
    @subjects = current_user.subjects
  end

  def show
    @subject = current_user.subjects.find(params[:id])
  end

  def new
    session[:subject_params] ||= {}
    @subject = Subject.new
  end

  def create
    session[:subject_params].deep_merge!(params[:subject]) if params[:subject]
    session[:subject_aulas]= params[:aulas] unless params[:aulas].nil?
    
    @subject = current_user.subjects.new(session[:subject_params])
    @subject.current_step = session[:subject_step]
    if  @subject.valid?
      if params[:back_button]
        @subject.previous_step
      elsif @subject.last_step?
        
        if @subject.all_valid?
          @subject.save
          @subject.create_course_subject_type_course(session[:subject_aulas], @subject.id) unless session[:subject_aulas].nil?
          # @subject.create_course_subject_type_exam(session[:subject_aulas], @subject.id) unless session[:subject_aulas].nil?
        end
      else
        @subject.next_step
      end
      session[:subject_step]= @subject.current_step
    end

    if @subject.new_record?
      render "new"
    else
      session[:subject_step] = session[:subject_params] = nil
      redirect_to subject_path(@subject)
    end
  end


  def edit
    session[:subject_params] ||= {}
    @subject = current_user.subjects.find(params[:id])
  end
 
  def update 
    updated = false 
    session[:subject_params].deep_merge!(params[:subject]) if params[:subject]
    session[:subject_aulas]= params[:aulas] unless params[:aulas].nil?
    session[:subject_id]= params[:id] unless params[:id].nil?

    @subject = current_user.subjects.new(session[:subject_params])
    @subject.current_step = session[:subject_step]

    if  @subject.valid?
      if params[:back_button]
        @subject.previous_step
      elsif @subject.last_step?

        if @subject.all_valid?
          @subject = current_user.subjects.find(session[:subject_id])
          @subject.update_attributes(session[:subject_params])
          @subject.course_subjects.destroy_all
          @subject.create_course_subject_type_course(session[:subject_aulas], @subject.id) unless session[:subject_aulas].nil?
          # @subject.create_course_subject_type_exam(params[:exames], @subject.id) unless params[:exames].nil?
          updated = true
        end
      else
        @subject.next_step
      end
      session[:subject_step]= @subject.current_step
    end

    unless updated
      render "edit"
    else
      session[:subject_step] = session[:subject_params]= session[:subject_aulas]= session[:subject_id] = nil
      redirect_to subject_path(@subject)
    end

  end
 
  def destroy
    subject = current_user.subjects.find(params[:id])
    subject.destroy
    redirect_to subjects_path
  end

end