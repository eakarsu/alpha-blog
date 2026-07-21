class Tag < ActiveRecord::Base
  has_many :article_tags, dependent: :destroy
  has_many :articles, through: :article_tags
  validates :name, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 40 }
  validates :slug, presence: true, uniqueness: true
  before_validation { self.slug = name.to_s.parameterize }
end
