# Whisper pub/sub listener
class RequirementSubscriber
  def self.after_commit(req)

    # we have to check each team that is
    # associated with the requirement's parent race.
    req.race.teams.each do |team|
      # check and do stuff if this team is now unfinalized for some reason
      team.unfinalize

      # check if the team now meets all finalization criteria and do stuff if so
      team.finalize
    end
  end
end
