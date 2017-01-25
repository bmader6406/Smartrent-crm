ActionMailer::Base.smtp_settings = {
  :address => "smtp.gmail.com",
  :port => 587,
  :domain => EMAIL_DOMAIN,
  :user_name => OPS_EMAIL,
  :password => OPS_PWD,
  :authentication => :login,
  :enable_starttls_auto => true
}

ABBR_ENV = case Rails.env
  when "production"
    ""
  when "stage"
    "[STG]"
  when "development"
    "[DEV]"
end