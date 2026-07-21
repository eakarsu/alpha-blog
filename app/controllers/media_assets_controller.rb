class MediaAssetsController < ApplicationController
  before_action :require_user
  before_action :set_article

  def create
    return head :forbidden unless current_user == @article.user || current_user.editor?
    asset = Publishing::MediaStore.save!(upload: params.require(:file), article: @article,
                                         actor: current_user, alt_text: params.require(:alt_text))
    AuditEvent.record!(actor: current_user, action: "media.created", subject: asset, request_id: request.request_id)
    redirect_to article_path(@article), notice: "Media uploaded."
  rescue ArgumentError => error
    redirect_to article_path(@article), alert: error.message
  end

  def destroy
    asset = @article.media_assets.find(params[:id])
    return head :forbidden unless current_user == @article.user || current_user.editor?
    Publishing::MediaStore.delete!(asset)
    asset.destroy!
    AuditEvent.record!(actor: current_user, action: "media.deleted", subject: asset, request_id: request.request_id)
    redirect_to article_path(@article), notice: "Media removed."
  end

  private

  def set_article
    @article = Article.find(params[:article_id])
  end
end
