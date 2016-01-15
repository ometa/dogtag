class Tier < ActiveRecord::Base
  include Wisper.model

  validates :price, :numericality => { :only_integer => true, :greater_than_or_equal_to => 0 }
  validates_with TierValidator

  # Single Table Inheritance: PaymentRequirement
  belongs_to :requirement

  def to_s
    price
  end
end
