class Page < ApplicationRecord
  extend FriendlyId
  friendly_id :title, use: :slugged

  has_paper_trail

  has_one :current_version, -> { reorder(created_at: :desc, id: :desc) }, class_name: "PaperTrail::Version", foreign_key: 'item_id'
  has_one :current_published_version, -> { reorder(created_at: :desc, id: :desc).where_object(status: 1) }, class_name: "PaperTrail::Version", foreign_key: 'item_id'
  has_many :media_items, as: :attachable
  has_many :page_slots
  belongs_to :featured_image, class_name: 'MediaItem'

  accepts_nested_attributes_for :page_slots, allow_destroy: true

  enum status: {
    published: 1,
    drafted: 2,
    scheduled: 3,
    pending: 4,
    hidden: 5
  }

  scope :by_id, -> (orderer = :desc) { order(id: orderer) }
  scope :by_title, -> (orderer = :asc) { order(title: orderer) }
  scope :by_slug, -> (orderer = :asc) { order(slug: orderer) }
  scope :by_created_at, -> (orderer = :desc) { order(created_at: orderer) }
  scope :by_updated_at, -> (orderer = :desc) { order(updated_at: orderer) }
  scope :by_status, -> (status) { where(status: status) }
  scope :search, -> (query) {
    where(self.columns.select{ |x| x.type == :string }.map(&:name).collect{ |x|
      x + ' LIKE :query'
    }.join(' OR '), query: "%#{query}%")
  }

  def blocks
    page_slots.includes(:blockable).collect(&:blockable)
  end

  private

    def should_generate_new_friendly_id?
      slug.blank?
    end
end
