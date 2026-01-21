class PoliciesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project
  before_action :set_policy, only: [:show, :edit, :update, :destroy, :toggle]

  def index
    @policies = @project.policies.order(:name)
    @violations = PolicyViolation.joins(:policy)
                                  .where(policies: { project_id: @project.id })
                                  .unresolved
                                  .recent
                                  .limit(10)
  end

  def show
    @violations = @policy.policy_violations.recent.limit(20)
  end

  def new
    @policy = @project.policies.build
  end

  def create
    @policy = @project.policies.build(policy_params)

    if @policy.save
      redirect_to project_policies_path(@project), notice: t("policies.messages.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @policy.update(policy_params)
      redirect_to project_policy_path(@project, @policy), notice: t("policies.messages.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @policy.destroy
    redirect_to project_policies_path(@project), notice: t("policies.messages.deleted")
  end

  def toggle
    @policy.update(enabled: !@policy.enabled?)

    respond_to do |format|
      format.html { redirect_back(fallback_location: project_policies_path(@project)) }
      format.turbo_stream
    end
  end

  private

  def set_project
    @project = current_user.projects.find(params[:project_id])
  end

  def set_policy
    @policy = @project.policies.find(params[:id])
  end

  def policy_params
    params.require(:policy).permit(:name, :description, :policy_type, :enabled, rules: {})
  end
end
