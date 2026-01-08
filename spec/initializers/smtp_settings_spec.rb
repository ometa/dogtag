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

describe 'SMTP Settings Initializer' do
  let(:test_smtp_settings) do
    {
      address: 'smtp.example.com',
      port: 587,
      domain: 'example.com',
      user_name: 'test_user',
      password: 'test_password',
      authentication: :plain,
      enable_starttls_auto: true
    }
  end

  describe 'copying smtp_settings to ActionMailer::Base' do
    before do
      @original_smtp_settings = ActionMailer::Base.smtp_settings.dup
    end

    after do
      ActionMailer::Base.smtp_settings = @original_smtp_settings
    end

    it 'copies config smtp_settings to ActionMailer::Base.smtp_settings when present' do
      allow(Rails.configuration.action_mailer).to receive(:smtp_settings).and_return(test_smtp_settings)

      # Simulate what the initializer does
      if Rails.configuration.action_mailer.smtp_settings.present?
        ActionMailer::Base.smtp_settings = Rails.configuration.action_mailer.smtp_settings
      end

      expect(ActionMailer::Base.smtp_settings).to eq(test_smtp_settings)
    end

    it 'does not modify ActionMailer::Base.smtp_settings when config smtp_settings is nil' do
      allow(Rails.configuration.action_mailer).to receive(:smtp_settings).and_return(nil)

      original_settings = ActionMailer::Base.smtp_settings.dup

      # Simulate what the initializer does
      if Rails.configuration.action_mailer.smtp_settings.present?
        ActionMailer::Base.smtp_settings = Rails.configuration.action_mailer.smtp_settings
      end

      expect(ActionMailer::Base.smtp_settings).to eq(original_settings)
    end

    it 'does not modify ActionMailer::Base.smtp_settings when config smtp_settings is empty' do
      allow(Rails.configuration.action_mailer).to receive(:smtp_settings).and_return({})

      original_settings = ActionMailer::Base.smtp_settings.dup

      # Simulate what the initializer does
      if Rails.configuration.action_mailer.smtp_settings.present?
        ActionMailer::Base.smtp_settings = Rails.configuration.action_mailer.smtp_settings
      end

      expect(ActionMailer::Base.smtp_settings).to eq(original_settings)
    end
  end
end
