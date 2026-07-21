require "digest"

class Article < ActiveRecord::Base
  STATUSES = %w[draft in_review changes_requested approved published archived].freeze

  belongs_to :user
  has_many :article_categories, dependent: :destroy
  has_many :categories, through: :article_categories
  has_many :article_tags, dependent: :destroy
  has_many :tags, through: :article_tags
  has_many :article_revisions, dependent: :restrict_with_error
  has_many :media_assets, dependent: :destroy

  validates :title, presence: true, length: { minimum: 3, maximum: 120 }
  validates :description, presence: true, length: { minimum: 10, maximum: 100_000 }
  validates :status, inclusion: { in: STATUSES }
  validates :slug, presence: true, uniqueness: true
  validates :seo_title, length: { maximum: 70 }, allow_blank: true
  validates :seo_description, length: { maximum: 160 }, allow_blank: true
  validate :published_articles_have_a_timestamp

  before_validation :assign_slug

  scope :visible_to_public, -> { where(status: "published").where("published_at <= ?", Time.current) }
  scope :newest_first, -> { order(published_at: :desc, created_at: :desc) }

  def transition_to!(target, actor:, reason: nil)
    Publishing::Policy.authorize_transition!(article: self, actor: actor, target: target)
    transaction do
      snapshot!(actor)
      update!(status: target, moderation_reason: reason,
              published_at: target == "published" ? Time.current : published_at)
      AuditEvent.record!(actor: actor, action: "article.#{target}", subject: self,
                         metadata: { from: status_before_last_save, reason: reason }.compact)
    end
  end

  def snapshot!(editor)
    article_revisions.create!(
      editor: editor,
      number: (article_revisions.maximum(:number) || 0) + 1,
      title: title,
      description: description,
      status: status,
      content_sha256: Digest::SHA256.hexdigest([title, description, status].join("\0"))
    )
  end

  private

  def assign_slug
    base = title.to_s.parameterize.presence || "article"
    candidate = base
    suffix = 1
    while self.class.where.not(id: id).exists?(slug: candidate)
      suffix += 1
      candidate = "#{base}-#{suffix}"
    end
    self.slug = candidate if slug.blank? || title_changed?
  end

  def published_articles_have_a_timestamp
    errors.add(:published_at, "is required") if status == "published" && published_at.blank?
  end
end
