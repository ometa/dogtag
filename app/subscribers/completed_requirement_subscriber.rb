# Whisper pub/sub listener
class CompletedRequirementSubscriber
  def self.after_commit(cr)
    # check and do stuff if this team is now unfinalized for some reason
    cr.team.unfinalize

    # check if the team now meets all finalization criteria and do stuff if so
    cr.team.finalize
  end
end
