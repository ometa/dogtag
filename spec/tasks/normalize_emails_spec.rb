# Copyright (C) 2024 Devin Breen
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
require 'rake'

describe 'db:normalize:emails' do
  before(:all) do
    Rake.application.rake_require 'tasks/normalize_emails'
    Rake::Task.define_task(:environment)
  end

  let(:run_task) do
    Rake::Task['db:normalize:emails'].reenable
    Rake::Task['db:normalize:emails'].invoke
  end

  describe 'normalizing User emails' do
    it 'converts uppercase emails to lowercase' do
      user = FactoryBot.create(:user)
      user.update_column(:email, 'UPPERCASE@EMAIL.COM')

      expect { run_task }.to output(/Updated User/).to_stdout

      expect(user.reload.email).to eq('uppercase@email.com')
    end

    it 'does not modify already lowercase emails' do
      user = FactoryBot.create(:user, email: 'lowercase@email.com')

      expect { run_task }.not_to output(/Updated User ##{user.id}/).to_stdout

      expect(user.reload.email).to eq('lowercase@email.com')
    end

    it 'handles mixed case emails' do
      user = FactoryBot.create(:user)
      user.update_column(:email, 'MixedCase@Email.Com')

      expect { run_task }.to output(/Updated User/).to_stdout

      expect(user.reload.email).to eq('mixedcase@email.com')
    end
  end

  describe 'normalizing Person emails' do
    let(:team) { FactoryBot.create(:team) }

    it 'converts uppercase emails to lowercase' do
      person = FactoryBot.create(:person, team: team)
      person.update_column(:email, 'UPPERCASE@EMAIL.COM')

      expect { run_task }.to output(/Updated Person/).to_stdout

      expect(person.reload.email).to eq('uppercase@email.com')
    end

    it 'does not modify already lowercase emails' do
      person = FactoryBot.create(:person, team: team, email: 'lowercase@email.com')

      expect { run_task }.not_to output(/Updated Person ##{person.id}/).to_stdout

      expect(person.reload.email).to eq('lowercase@email.com')
    end
  end

  describe 'normalizing ClassyCacheOrgMember emails' do
    it 'converts uppercase emails to lowercase' do
      member = ClassyCacheOrgMember.create!(
        classy_org_id: 1,
        email: 'test@example.com',
        classy_member_id: 1,
        classy_updated_at: Time.current
      )
      member.update_column(:email, 'UPPERCASE@EMAIL.COM')

      expect { run_task }.to output(/Updated ClassyCacheOrgMember/).to_stdout

      expect(member.reload.email).to eq('uppercase@email.com')
    end

    it 'does not modify already lowercase emails' do
      member = ClassyCacheOrgMember.create!(
        classy_org_id: 2,
        email: 'lowercase@email.com',
        classy_member_id: 2,
        classy_updated_at: Time.current
      )

      expect { run_task }.not_to output(/Updated ClassyCacheOrgMember ##{member.id}/).to_stdout

      expect(member.reload.email).to eq('lowercase@email.com')
    end
  end

  describe 'output summary' do
    it 'reports total records updated' do
      user = FactoryBot.create(:user)
      user.update_column(:email, 'USER@EMAIL.COM')

      expect { run_task }.to output(/Total records updated: 1/).to_stdout
    end
  end
end

describe 'db:normalize:emails_check' do
  before(:all) do
    Rake.application.rake_require 'tasks/normalize_emails'
    Rake::Task.define_task(:environment)
  end

  let(:run_task) do
    Rake::Task['db:normalize:emails_check'].reenable
    Rake::Task['db:normalize:emails_check'].invoke
  end

  it 'reports users with uppercase emails without modifying them' do
    user = FactoryBot.create(:user)
    user.update_column(:email, 'UPPERCASE@EMAIL.COM')

    expect { run_task }.to output(/User ##{user.id}: UPPERCASE@EMAIL.COM/).to_stdout

    # Email should NOT be modified
    expect(user.reload.email).to eq('UPPERCASE@EMAIL.COM')
  end

  it 'reports total count of records found' do
    user = FactoryBot.create(:user)
    user.update_column(:email, 'UPPERCASE@EMAIL.COM')

    expect { run_task }.to output(/Total records with uppercase emails: 1/).to_stdout
  end
end
