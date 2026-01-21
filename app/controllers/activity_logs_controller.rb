class ActivityLogsController < ApplicationController
  before_action :authenticate_user!

  def index
    @logs = accessible_logs
              .recent
              .includes(:user, :trackable)
              .page(params[:page])
              .per(50)

    @filter = params[:filter]

    if @filter.present?
      @logs = @logs.where("action LIKE ?", "#{@filter}%")
    end
  end

  private

  def accessible_logs
    # Users can see logs for:
    # 1. Their own actions
    # 2. Actions on their projects
    # 3. Actions in their organizations
    project_ids = current_user.projects.pluck(:id)
    org_ids = current_user.organizations.pluck(:id)

    ActivityLog.where(user: current_user)
               .or(ActivityLog.where(trackable_type: "Project", trackable_id: project_ids))
               .or(ActivityLog.where(trackable_type: "Organization", trackable_id: org_ids))
  end
end
