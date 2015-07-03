# This file is automatically copied into RAILS_ROOT/initializers

config_file = "#{Rails.root.to_s}/config/smtp_gmail.yml"
raise "Sorry, you must have #{config_file}" unless File.exists?(config_file)

SMTP_ACCOUNTS = YAML.load_file(config_file)

ActionMailer::Base.smtp_settings = {
  :address => "smtp.gmail.com",
  :port => 587,
  :domain => "hy.ly",
  :authentication => :login,
  :enable_starttls_auto => true
}.merge(SMTP_ACCOUNTS[:alerts]) # Configuration options override default options, default is alerts@hy.ly

ABBR_ENV = case Rails.env
  when "production"
    ""
  when "stage"
    "[STG]"
  when "development"
    "[DEV]"
end
