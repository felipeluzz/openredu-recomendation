class CoursesController < BaseController
  layout "environment"
  load_resource :environment
  load_and_authorize_resource :course, :through => :environment, :except => [:index]

  rescue_from CanCan::AccessDenied do |exception|
    raise if cannot? :preview, @course

    flash[:notice] = "Você não tem acesso a essa página"
    redirect_to preview_environment_course_path(@environment, @course)
  end

  def show
    @spaces = @course.spaces.published.
      paginate(:page => params[:page], :order => 'name ASC',
               :per_page => AppConfig.items_per_page)
    @course_users = @course.approved_users.all(:limit => 9)

    respond_to do |format|
      format.html do
        render :template => 'courses/new/show', :layout => 'new/application'
      end
      format.js { render :template => 'courses/new/show' }
    end
  end

  def edit
  end

  def destroy
    @course.destroy

    respond_to do |format|
      flash[:notice] = "Curso removido."
      format.html { redirect_to(environment_path(@environment)) }
      format.xml  { head :ok }
    end
  end

  def update
    respond_to do |format|
      if @course.update_attributes(params[:course])
        if params[:course][:subscription_type].eql? "1" # Entrada de membros passou a ser livre, aprovar todos os membros pendentes
          UserCourseAssociation.update_all("state = 'approved'", ["course_id = ? AND state = 'waiting'", @course.id])
        end

        flash[:notice] = 'O curso foi editado.'
        format.html { redirect_to(environment_course_path(@environment, @course)) }
        format.xml { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @course.errors, :status => :unprocessable_entity }
      end
    end
  end

  def new
  end

  def create
    authorize! :manage, @environment #Talvez seja necessario pois o @environment não está sendo autorizado.

    @course.owner = current_user
    @plan = Plan.from_preset(params[:plan])
    @plan.user = current_user
    @course.verify_path! @environment.id

    respond_to do |format|
      if @course.save
        @course.plan = @plan
        @environment.courses << @course
        format.html { redirect_to environment_course_path(@environment, @course) }
      else
        format.html { render :action => :new }
      end
    end

  end

  def index
    cond = {}
    @user = User.find(params[:user_id].to_i) if params.has_key?(:user_id)
    unless ( !@environment.nil? && can?(:manage, @environment) ) or ( !@user.nil? && can?(:manage, @user) )
      cond[:published] = true
    end

    paginating_params = {
      :conditions => cond,
      :page => params[:page],
      :order => (params[:sort]) ? params[:sort] + ' DESC' : 'created_at DESC',
      :per_page => 8
    }

    if @environment
      @courses = @environment.courses
    elsif params.has_key?(:user_id)
      paginating_params[:per_page] = 6
      @courses = @user.courses
    else
      @courses = Course.published.all
    end

    if params[:search] # search
      @courses = @courses.name_like_all(params[:search].to_s.split).ascend_by_name.paginate(paginating_params)
    else
      @courses = @courses.paginate(paginating_params)
    end

    respond_to do |format|
      format.html do
        unless params[:environment_id]
          render :layout => 'application'
        end
      end
      format.js
    end
  end

  # Visão do Course para usuários não-membros.
  def preview
  end

  # Aba Disciplinas.
  def admin_spaces
    # FIXME Refatorar para o modelo (conditions)
    @spaces = Space.paginate(:conditions => ["course_id = ?", @course.id],
                             :include => :owner,
                             :page => params[:page],
                             :order => 'updated_at DESC',
                             :per_page => AppConfig.items_per_page)

    respond_to do |format|
      format.html
      format.js
    end
  end

  # Aba Moderação de Membros.
  def admin_members_requests
    # FIXME Refatorar para o modelo (conditions)
    @pending_members = UserCourseAssociation.paginate(:conditions => ["state LIKE 'waiting' AND course_id = ?", @course.id],
                                                      :page => params[:page],
                                                      :order => 'updated_at DESC',
                                                      :per_page => AppConfig.items_per_page)
    respond_to do |format|
      format.html
      format.js
    end

  end

  # Modera os usuários.
  def moderate_members_requests
    if params[:member].nil?
      flash[:notice] = "Escolha, pelo menos, algum usuário."
    else
      approved = params[:member].reject{|k,v| v == 'reject'}
      rejected = params[:member].reject{|k,v| v == 'approve'}

      approved.keys.each do |user_id|
        UserCourseAssociation.update_all("state = 'approved'", :user_id => user_id,  :course_id => @course.id)
      end

      rejected.keys.each do |user_id|
        UserCourseAssociation.update_all("state = 'rejected'", :user_id => user_id,  :course_id => @course.id)
      end

      @approved_members = User.all(:conditions => ["id IN (?)", approved.keys]) unless approved.empty?
      @rejected_members = User.all(:conditions => ["id IN (?)", rejected.keys]) unless rejected.empty?

      # Cria as associações no Environment do Course e em todos os seus Spaces.
      if @approved_members
        @approved_members.each do |member|
          UserEnvironmentAssociation.create(:user_id => member.id, :environment_id => @course.environment.id,
                                            :role_id => Role[:student].id)
          @course.spaces.each do |space|
            UserSpaceAssociation.create(:user_id => member.id, :space_id => space.id,
                                        :role_id => Role[:student].id, :status => "approved") #FIXME tirar status quando remover moderacao de space
          end

          UserNotifier.deliver_approve_membership(member, @course) # TODO fazer isso em batch
        end
      end

      if @rejected_members
        @rejected_members.each do |member|
          UserNotifier.deliver_reject_membership(member, @course) #TODO fazer isso em batch
        end
      end

      flash[:notice] = 'Membros moderados!'
    end

    redirect_to admin_members_requests_environment_course_path(@environment, @course)
  end

  # Associa um usuário a um Course (Ação de participar).
  def join
    association = UserCourseAssociation.create(:user_id => current_user.id, :course_id => @course.id,
                                               :role_id => Role[:member].id)

    if @course.subscription_type.eql? 1 # Todos podem participar, sem moderação
      association.approve!

      # Cria as associações no Environment do Course e em todos os seus Spaces.
      UserEnvironmentAssociation.create(:user_id => current_user.id, :environment_id => @course.environment.id,
                                        :role_id => Role[:member].id)
      @course.spaces.each do |space|
        UserSpaceAssociation.create(:user_id => current_user.id, :space_id => space.id,
                                    :role_id => Role[:member].id, :status => "approved") #FIXME tirar status quando remover moderacao de space
      end

      flash[:notice] = "Você agora faz parte do curso #{@course.name}"
      redirect_to environment_course_path(@course.environment, @course)
    else
      flash[:notice] = "Seu pedido de participação foi feito. Aguarde a moderação."
      redirect_to preview_environment_course_path(@course.environment, @course)
    end
  end


  # Desassocia um usuário de um Course (Ação de sair do Course).
  def unjoin
    course_association = current_user.get_association_with(@course)
    course_association.destroy
    @course.spaces.each do |space|
      space_association = current_user.get_association_with(space)
      space_association.destroy
    end

    flash[:notice] = "Você não participa mais do curso #{@course.name}"
    redirect_to environment_course_path(@course.environment, @course)
  end

  def publish
    if @course.can_be_published?
      @course.published = 1
      @course.save
      flash[:notice] = "O curso #{@course.name} foi publicado."
    else
      flash[:notice] = "O curso não pode ser publicado, crie e publique disciplinas!"
    end

    redirect_to environment_course_path(@environment, @course)
  end

  def unpublish
    @course.published = 0
    @course.save

    flash[:notice] = "O curso #{@course.name} foi despublicado."
    redirect_to environment_course_path(@environment, @course)
  end

  # Aba Membros.
  def admin_members
    @memberships = UserCourseAssociation.paginate(
      :conditions => ["course_id = ? AND state LIKE ? ", @course.id, 'approved'],
      :include => [{ :user => {:user_space_associations => :space} }],
      :page => params[:page],
      :order => 'updated_at DESC',
      :per_page => AppConfig.items_per_page)

    respond_to do |format|
      format.html
      format.js { render :template => 'shared/admin_members' }
    end
  end

  # Remove um ou mais usuários de um Environment destruindo todos os relacionamentos
  # entre usuário e os níveis mais baixos da hierarquia.
  def destroy_members
    # Course.id do environment
    spaces = @course.spaces
    users_ids = []
    users_ids = params[:users].collect{|u| u.to_i} if params[:users]

    unless users_ids.empty?
      User.find(:all,
                :conditions => {:id => users_ids},
                :include => [:user_course_associations,
                  :user_space_associations]).each do |user|

        user.spaces.delete(spaces)
        user.courses.delete(@course)
                  end
      flash[:notice] = "Os usuários foram removidos do curso #{@course.name}"
    end

    respond_to do |format|
      format.html { redirect_to :action => :admin_members }
    end
  end

  def search_users_admin
    roles = []
    roles = params[:role_filter].collect {|r| r.to_i} if params[:role_filter]
    keyword = []
    keyword = params[:search_user] || nil

    @memberships = UserCourseAssociation.with_roles(roles)
    @memberships = @memberships.with_keyword(keyword).paginate(
      :conditions => ["user_course_associations.course_id = ?", @course.id],
      :include => [{ :user => {:user_space_associations => :space} }],
      :page => params[:page],
      :order => 'user_course_associations.updated_at DESC',
      :per_page => AppConfig.items_per_page)

      respond_to do |format|
        format.js do
          render :update do |page|
            page.replace_html 'user_list', :partial => 'user_list_admin', :locals => {:memberships => @memberships}
          end
        end
      end
  end

  # Listagem de usuários do Course
  def users
    @course_users = @course.approved_users.all(:limit => 9) # sidebar
    @users = @course.approved_users.
      paginate(:page => params[:page], :order => 'first_name ASC', :per_page => 18)

    respond_to do |format|
      format.html do
        render :template => 'courses/new/users', :layout => 'new/application'
      end
      format.js { render :template => 'courses/new/users' }
    end
  end
end
