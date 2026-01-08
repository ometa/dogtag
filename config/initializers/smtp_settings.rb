# Workaround for Rails 7 issue where smtp_settings get reset to nil
# when ActionMailer::Base is loaded.
# See: https://github.com/rails/rails/issues/44059
Rails.application.config.after_initialize do
  if Rails.configuration.action_mailer.smtp_settings.present?
    ActionMailer::Base.smtp_settings = Rails.configuration.action_mailer.smtp_settings
  end
end
