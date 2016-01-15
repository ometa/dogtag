# Whisper pub/sub listener
class RaceSubscriber
  def self.after_commit(race)
    race.teams.each do |team|
      team.unfinalize
      team.finalize
    end
  end
end

