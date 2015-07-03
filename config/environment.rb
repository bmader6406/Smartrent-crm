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

OPS_U = 'ops@hy.ly'
OPS_P = 'HcmcNyc!@34'

DROPBOX_KEY = "mz42zotb5v03alt"
AVIARY_KEY = "jk1wj4kf7bt36inm"

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

###

TWILIO_SID = "AC98548e50553210aa39deb89e6a8ffb1b"
TWILIO_TOKEN = "643e67e6da78361b3436d7781d78f5cb"
TWILIO_NUMBER = "+1 260-535-0148"

TWILIO_P2P_SID = Rails.env.production? ? "APf050c35b938ebb859aa802e25f7f7d71" : "AP9bebd11d0f668dd667158695dea83119"
TWILIO_W2P_SID = Rails.env.production? ? "AP619d8d6bbadf103902cf8c550c1448b7" : "AP6343c3b276cf4da851ceeb07e0ab0438"
TWILIO_W2P_CLIENT = "Web"

CONVO_EMAIL = "conversation@hy.ly"
CONVO_PWD = "C0nversation"

# Initialize the Rails application.
Rails.application.initialize!
