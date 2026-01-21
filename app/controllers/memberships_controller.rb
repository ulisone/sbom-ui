class MembershipsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_organization
  before_action :authorize_admin!
  before_action :set_membership, only: [:update, :destroy]

  def create
    user = User.find_by(email: membership_params[:email]&.downcase)

    if user.nil?
      redirect_to @organization, alert: I18n.t("organizations.members.user_not_found")
      return
    end

    if @organization.member?(user)
      redirect_to @organization, alert: I18n.t("organizations.members.already_member")
      return
    end

    @membership = @organization.memberships.build(
      user: user,
      role: membership_params[:role] || Organization::MEMBER,
      invited_by: current_user,
      accepted_at: Time.current
    )

    if @membership.save
      redirect_to @organization, notice: I18n.t("organizations.members.added")
    else
      redirect_to @organization, alert: @membership.errors.full_messages.join(", ")
    end
  end

  def update
    if @membership.owner? && membership_params[:role] != Organization::OWNER
      # Check if there's at least one other owner
      unless @organization.memberships.owners.where.not(id: @membership.id).exists?
        redirect_to @organization, alert: I18n.t("organizations.members.must_have_owner")
        return
      end
    end

    if @membership.update(role: membership_params[:role])
      redirect_to @organization, notice: I18n.t("organizations.members.updated")
    else
      redirect_to @organization, alert: @membership.errors.full_messages.join(", ")
    end
  end

  def destroy
    if @membership.owner?
      # Check if there's at least one other owner
      unless @organization.memberships.owners.where.not(id: @membership.id).exists?
        redirect_to @organization, alert: I18n.t("organizations.members.must_have_owner")
        return
      end
    end

    if @membership.user == current_user
      redirect_to @organization, alert: I18n.t("organizations.members.cannot_remove_self")
      return
    end

    @membership.destroy
    redirect_to @organization, notice: I18n.t("organizations.members.removed")
  end

  private

  def set_organization
    @organization = Organization.find(params[:organization_id])
  end

  def set_membership
    @membership = @organization.memberships.find(params[:id])
  end

  def membership_params
    params.require(:membership).permit(:email, :role)
  end

  def authorize_admin!
    unless @organization.can_manage?(current_user)
      redirect_to @organization, alert: I18n.t("organizations.messages.unauthorized")
    end
  end
end
