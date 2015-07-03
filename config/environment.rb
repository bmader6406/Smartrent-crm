# Load the Rails application.
require File.expand_path('../application', __FILE__)

NIMDA_U, NIMDA_P = "hylynimda", "ZXCV!@34asdf"

#Twitter CRM app of jjjsllc
TWITTER_KEY = "VnbSsb1JvcaIJEqd3OTOg"
TWITTER_SECRET = "2U5VYZkeImzQ022EGwFNzgmQnjk9pM2ULMNQj9xhM8"
TWITTER_ACCESS_TOKEN = "120244684-vutyefi4Ra65QwFDG0DniCX2wF2GvEdAmA4rfmTx"
TWITTER_ACCESS_SECRET = "gGQ2TDNOse4zRLBejfPCv17uYRdNLRqiHblH9yPlE"

FACEBOOK_ID = 173801062636343
FACEBOOK_KEY = "631826feeb542f675961c085a3004e15"
FACEBOOK_SECRET = "f55a19ee9055981f0e6cf703fefd6d44"

# CRM Leads: https://console.developers.google.com/project/289130776929
GOOGLE_KEY = "AIzaSyDgtk2nMDv_NKRkbTKsZ2HxN1bW0JRXMcE"
GOOGLE_APP_ID = "289130776929.apps.googleusercontent.com"
GOOGLE_SECRET = "4c-Nk5nT_FxcPER-z-ii9ooD"

LINKEDIN_KEY = "hodfqgjxzj6a"
LINKEDIN_SECRET = "6J2t0C0K5QFBImuv"

AWS_KEY = 'AKIAIRKGJLR7V7ZO25GQ'
AWS_SECRET = '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'

#########

RETRY_LIMIT = 3
RETRY_DELAY = 30
TMP_DIR = "/tmp/"

# remove soon
MULTI_SENDS_ENABLED_TS = Time.parse("2013-12-09 11:00:00 UTC").to_i
DEPLOYED_AT = Time.now.to_i
VERIFIED_DOMAINS = "hy.ly bozzuto.com"

# Initialize the Rails application.
Rails.application.initialize!
