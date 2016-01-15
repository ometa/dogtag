# Whisper pub/sub listener
class TeamSubscriber
  def self.after_commit(team)
    # check and do stuff if this team is now unfinalized for some reason
    team.unfinalize

    # check if the team now meets all finalization criteria and do stuff if so
    team.finalize
  end
end
