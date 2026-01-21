class OrganizationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_organization, only: [:show, :edit, :update, :destroy]
  before_action :authorize_member!, only: [:show]
  before_action :authorize_admin!, only: [:edit, :update, :destroy]

  def index
    @organizations = current_user.organizations.ordered
  end

  def show
    @memberships = @organization.memberships.includes(:user).order(:created_at)
    @projects = @organization.projects.includes(:scans).order(updated_at: :desc)
  end

  def new
    @organization = Organization.new
  end

  def create
    @organization = Organization.new(organization_params)

    if @organization.save
      # Add creator as owner
      @organization.add_member(current_user, role: Organization::OWNER)
      redirect_to @organization, notice: I18n.t("organizations.messages.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @organization.update(organization_params)
      redirect_to @organization, notice: I18n.t("organizations.messages.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @organization.destroy
    redirect_to organizations_path, notice: I18n.t("organizations.messages.deleted")
  end

  private

  def set_organization
    @organization = Organization.find(params[:id])
  end

  def organization_params
    params.require(:organization).permit(:name, :description)
  end

  def authorize_member!
    unless @organization.member?(current_user)
      redirect_to organizations_path, alert: I18n.t("organizations.messages.unauthorized")
    end
  end

  def authorize_admin!
    unless @organization.can_manage?(current_user)
      redirect_to @organization, alert: I18n.t("organizations.messages.unauthorized")
    end
  end
end
