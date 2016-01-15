# Base model to be overridden by more specific requirements.
class Requirement < ActiveRecord::Base
  include Wisper.model

  validates_presence_of :name

  belongs_to :race
  validates_presence_of :race

  has_many :completed_requirements
  has_many :teams, :through => :completed_requirements

  ALLOWED_TYPES = [['Payment', 'PaymentRequirement']]

  class << self
    def allowed_types
      ALLOWED_TYPES
    end
  end

  def enabled?
    raise "Implement Me!"
  end

  def cr_for(team)
    record = CompletedRequirement.where(:team_id => team.id, :requirement_id => id).first
    record.present? ? record : nil
  end

  def completed?(team)
    CompletedRequirement.where(:team_id => team.id, :requirement_id => id).present?
  end

  # todo: figure out how to allow only child classes to call this method.
  # todo: move JSON and is_a? Hash calls into the model
  def complete(team_id, user, metadata = {})
    cr = CompletedRequirement.new(
      :requirement_id => id,
      :team_id => team_id,
      :user => user,
      :metadata => JSON.generate(metadata))
    return cr if cr.save
    false
  end

end
