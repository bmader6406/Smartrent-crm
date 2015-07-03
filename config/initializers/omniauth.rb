OmniAuth.config.full_host = "http://#{HOST}"

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :twitter, TWITTER_KEY, TWITTER_SECRET
  provider :facebook, FACEBOOK_ID, FACEBOOK_SECRET
  provider :google_oauth2, GOOGLE_APP_ID, GOOGLE_SECRET
  provider :linkedin, LINKEDIN_KEY, LINKEDIN_SECRET
end