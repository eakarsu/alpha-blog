class PublishingImportsController < ApplicationController
  before_action :require_user

  def create
    return head :forbidden unless current_user.administrator?
    Publishing::Archive.import!(params.require(:archive).read(10.megabytes), actor: current_user)
    redirect_to articles_path, notice: "Archive imported."
  rescue JSON::ParserError, ArgumentError, ActiveRecord::RecordInvalid => error
    redirect_to articles_path, alert: "Import rejected: #{error.message}"
  end
end
