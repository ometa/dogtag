# Whisper pub/sub listener
class PeopleSubscriber
  def self.after_commit(person)
    # check and do stuff if this team is now unfinalized for some reason
    person.team.unfinalize

    # check if the team now meets all finalization criteria and do stuff if so
    person.team.finalize
  end
end

