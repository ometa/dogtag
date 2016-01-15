# Whisper pub/sub listener
class TierSubscriber
  def self.after_commit(tier)

    # we have to check each team that is
    # associated with the tier's requirement's parent race.
    tier.requirement.race.teams.each do |team|
      # check and do stuff if this team is now unfinalized for some reason
      team.unfinalize

      # check if the team now meets all finalization criteria and do stuff if so
      team.finalize
    end
  end
end
