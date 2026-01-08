# Copyright (C) 2013 Devin Breen
# This file is part of dogtag <https://github.com/chiditarod/dogtag>.
#
# dogtag is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# dogtag is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with dogtag.  If not, see <http://www.gnu.org/licenses/>.
require 'spec_helper'

describe Person do

  context "when the time is after the final edits window" do
    let(:race) { FactoryBot.create :race, :after_final_edits_window }
    let(:team) { FactoryBot.create :team, :with_people, people_count: 1, race: race }
    let(:person) { team.people.first }

    it "prevents updating" do
      expect do
        name = "The Dude"
        person.first_name = name
        person.save
      end.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  context "when the time is in the final edits window" do
    let(:race) { FactoryBot.create :race, :in_final_edits_window }
    let(:team) { FactoryBot.create :team, :with_people, people_count: 1, race: race }
    let(:person) { team.people.first }

    it "allows updating" do
      name = "The Dude"
      person.first_name = name
      person.save
      expect(person.reload.first_name).to eq(name)
    end
  end

  describe '#registered_for_race' do
    it 'returns all the people on finalized teams in a race' do
      reg = FactoryBot.create :finalized_team
      expect(Person.registered_for_race reg.race_id).to eq(reg.people)
    end

    it 'does not return people for non-finalized teams in a race' do
      reg = FactoryBot.create :team, :with_people
      expect(Person.registered_for_race reg.race_id).to eq([])
    end

    it 'filters out all emails with the word "unknown"' do
      reg = FactoryBot.create :finalized_team
      person = reg.people.first
      person.email = 'unknown@gmail.com'
      person.save
      expect(Person.registered_for_race(reg.race_id).count).to eq((reg.race.people_per_team - 1))
    end
  end
end

describe 'validation' do
  it 'passes with all required parameters' do
    expect(FactoryBot.build(:person).valid?).to eq(true)
  end

  it 'fails with invalid years of experience' do
    expect(FactoryBot.build(:person, :experience => -10)).to be_invalid
  end

  ['bad@email', 'bad@email.', 'bademail.com', '@bademail.com', 'bad@email.a'].each do |email|
    it "fails on bad email address: #{email}" do
      expect(FactoryBot.build(:person, email: email)).to be_invalid
    end
  end

  describe 'email downcasing' do
    let(:team) { FactoryBot.create :team }

    it 'downcases email before validation' do
      person = FactoryBot.build(:person, team: team, email: 'TestPerson@Example.COM')
      person.valid?
      expect(person.email).to eq('testperson@example.com')
    end

    it 'saves email as lowercase' do
      person = FactoryBot.create(:person, team: team, email: 'UPPERCASE@EMAIL.COM')
      expect(person.reload.email).to eq('uppercase@email.com')
    end

    it 'handles mixed case emails' do
      person = FactoryBot.create(:person, team: team, email: 'MixedCase@Email.Com')
      expect(person.reload.email).to eq('mixedcase@email.com')
    end

    it 'does not modify already lowercase emails' do
      person = FactoryBot.create(:person, team: team, email: 'lowercase@email.com')
      expect(person.reload.email).to eq('lowercase@email.com')
    end

    context 'when email bypasses callback' do
      it 'fails validation if email contains uppercase characters' do
        person = FactoryBot.create(:person, team: team)
        # Bypass the callback by directly updating the column
        person.update_column(:email, 'Uppercase@Email.Com')
        # Skip callback to test the validation directly
        Person.skip_callback(:validation, :before, :downcase_email)
        begin
          person.reload
          expect(person).not_to be_valid
          expect(person.errors[:email]).to include('must be lowercase')
        ensure
          Person.set_callback(:validation, :before, :downcase_email)
        end
      end
    end
  end

  it 'passes when twitter starts with an @ sign' do
    expect(FactoryBot.build(:person, :twitter => 'bad')).to be_invalid
    expect(FactoryBot.build(:person, :twitter => '@good')).to be_valid
  end

  it 'converts phone numbers into the right format' do
    person = FactoryBot.build(:person)
    [1111111111, "1111111111"].each do |num|
      person.phone = num
      expect(person).to be_valid
    end
  end

  it 'fails with poorly formed zipcode' do
    person = FactoryBot.build(:person)
    person.zipcode = "a"
    expect(person).to be_invalid
  end

  it 'fails with poorly formed phone number' do
    person = FactoryBot.build(:person)
    person.phone = "abc123"
    expect(person).to be_invalid
  end

  it 'fails if the team is already full' do
    team = FactoryBot.create :team, :with_enough_people
    person = FactoryBot.build :person, team_id: team.id
    expect(person).to be_invalid
    expect(person.errors.messages[:maximum]).to eq(['people already added to this team'])
  end
end
