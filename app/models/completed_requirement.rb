# Intermediate model between a Team and Requirement
# User indicates which user made the association
class CompletedRequirement < ActiveRecord::Base
  include Wisper.model

  belongs_to :team
  belongs_to :requirement
  belongs_to :user

  validates_presence_of :team, :requirement, :user
  validates_uniqueness_of :team, :scope => [:requirement], :allow_nil => true, :message => 'has already completed this requirement.'
  validates_uniqueness_of :requirement, :scope => [:team], :allow_nil => true, :message => 'has already been completed for that team'

  def metadata
    m = read_attribute :metadata
    return m if m.is_a?(Hash)
    return JSON.load m
  end
end
