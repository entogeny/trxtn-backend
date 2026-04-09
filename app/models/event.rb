class Event < ApplicationRecord

  include SoftDeletable

  belongs_to :owner,   class_name: "User", optional: true
  belongs_to :creator, polymorphic: true,  optional: true

  validates :description, presence: true
  validates :name,        presence: true
  validates :start_at,    presence: true
  validate  :end_at_after_start_at, if: -> { end_at.present? }

  private

  def end_at_after_start_at
    if start_at.blank?
      return
    end

    if end_at <= start_at
      errors.add(:end_at, "must be after start_at")
    end
  end

end
