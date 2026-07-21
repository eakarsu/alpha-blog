class ArticlesController < ApplicationController
  before_action :set_article, only: %i[edit update show destroy submit_for_review request_changes approve publish archive]
  before_action :require_user, except: %i[index show]
  before_action :require_owner_or_editor, only: %i[edit update destroy submit_for_review archive]
  before_action :require_editor, only: %i[request_changes approve publish]

  def new
    @article = Article.new
  end

  def create
    Publishing::RateLimiter.check!(identity: current_user.id, operation: "article.create", limit: 20, window: 1.hour)
    @article = current_user.articles.new(article_params.merge(status: "draft"))
    apply_tags
    if @article.save
      @article.snapshot!(current_user)
      AuditEvent.record!(actor: current_user, action: "article.created", subject: @article, request_id: request.request_id)
      redirect_to article_path(@article), notice: "Draft created."
    else
      render :new, status: :unprocessable_entity
    end
  rescue SecurityError => error
    render plain: error.message, status: :too_many_requests
  end

  def show
    return if @article.status == "published" || (logged_in? && (current_user == @article.user || current_user.editor?))
    head :not_found
  end

  def edit; end

  def update
    @article.assign_attributes(article_params)
    apply_tags
    if @article.save
      @article.snapshot!(current_user)
      AuditEvent.record!(actor: current_user, action: "article.updated", subject: @article, request_id: request.request_id)
      redirect_to article_path(@article), notice: "Draft updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def index
    source = logged_in? && current_user.editor? ? Article.all : Article.visible_to_public
    query = params[:q].to_s.strip
    if query.present?
      pattern = "%#{ActiveRecord::Base.sanitize_sql_like(query)}%"
      source = source.where("title LIKE ? OR description LIKE ?", pattern, pattern)
    end
    source = source.joins(:categories).where(categories: { name: params[:category] }).distinct if params[:category].present?
    source = source.joins(:tags).where(tags: { slug: params[:tag] }).distinct if params[:tag].present?
    @articles = source.newest_first.paginate(page: params[:page], per_page: 20)
  end

  def destroy
    @article.update!(status: "archived")
    AuditEvent.record!(actor: current_user, action: "article.archived", subject: @article, request_id: request.request_id)
    redirect_to articles_path, notice: "Article archived."
  end

  %w[submit_for_review request_changes approve publish archive].each do |action|
    define_method(action) do
      target = { "submit_for_review" => "in_review", "request_changes" => "changes_requested",
                 "approve" => "approved", "publish" => "published", "archive" => "archived" }.fetch(action)
      @article.transition_to!(target, actor: current_user, reason: params[:reason])
      redirect_to article_path(@article), notice: "Article moved to #{target.humanize}."
    rescue ArgumentError, SecurityError => error
      redirect_to article_path(@article), alert: error.message
    end
  end

  private

  def article_params
    params.require(:article).permit(:title, :description, :seo_title, :seo_description, :canonical_url, category_ids: [])
  end

  def apply_tags
    return unless params.dig(:article, :tag_names)
    names = params[:article][:tag_names].split(",").map(&:strip).reject(&:blank?).uniq.first(10)
    @article.tags = names.map { |name| Tag.find_or_create_by!(name: name) }
  end

  def set_article
    @article = Article.find(params[:id])
  end

  def require_owner_or_editor
    head :forbidden unless current_user == @article.user || current_user&.editor?
  end

  def require_editor
    head :forbidden unless current_user&.editor?
  end
end
