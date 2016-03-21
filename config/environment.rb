# Load the Rails application.
require File.expand_path('../application', __FILE__)

NIMDA_U, NIMDA_P = "crmnimda", "CRMn1md4"

RETRY_LIMIT = 3
RETRY_DELAY = 30
TMP_DIR = "/mnt/exim-data/"

### Login with ... (optional)
TWITTER_KEY = ""
TWITTER_SECRET = ""

FACEBOOK_ID = ""
FACEBOOK_SECRET = ""

LINKEDIN_KEY = ""
LINKEDIN_SECRET = ""

# Google file picker ( https://console.developers.google.com/project/289130776929 )
GOOGLE_KEY = "AIzaSyDgtk2nMDv_NKRkbTKsZ2HxN1bW0JRXMcE"
GOOGLE_APP_ID = "289130776929.apps.googleusercontent.com"
GOOGLE_SECRET = "4c-Nk5nT_FxcPER-z-ii9ooD"

# Dropbox file picker
DROPBOX_KEY = "mz42zotb5v03alt"

### Resident stream - phone
TWILIO_SID = "AC98548e50553210aa39deb89e6a8ffb1b"
TWILIO_TOKEN = "643e67e6da78361b3436d7781d78f5cb"
TWILIO_NUMBER = "+1 260-535-0148"

TWILIO_P2P_SID = Rails.env.production? ? "APf050c35b938ebb859aa802e25f7f7d71" : "AP9bebd11d0f668dd667158695dea83119"

# Resident stream - email conversation
CONVO_EMAIL = "conversation@hy.ly"
CONVO_PWD = "C0nversAtion"

# SES monitor
OPS_U = 'ops@hy.ly'
OPS_P = 'HcmcNyc!@34'

# AWS SES & S3
AWS_KEY = 'AKIAIRKGJLR7V7ZO25GQ'
AWS_SECRET = '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'


US_STATES = {
  "AL" => "Alabama",
  "AK" => "Alaska",
  "AZ" => "Arizona",
  "AR" => "Arkansas",
  "CA" => "California",
  "CO" => "Colorado",
  "CT" => "Connecticut",
  "DE" => "Delaware",
  "DC" => "District of Columbia",
  "FL" => "Florida",
  "GA" => "Georgia",
  "HI" => "Hawaii",
  "ID" => "Idaho",
  "IL" => "Illinois",
  "IN" => "Indiana",
  "IA" => "Iowa",
  "KS" => "Kansas",
  "KY" => "Kentucky",
  "LA" => "Louisiana",
  "ME" => "Maine",
  "MD" => "Maryland",
  "MA" => "Massachusetts",
  "MI" => "Michigan",
  "MN" => "Minnesota",
  "MS" => "Mississippi",
  "MO" => "Missouri",
  "MT" => "Montana",
  "NE" => "Nebraska",
  "NV" => "Nevada",
  "NH" => "New Hampshire",
  "NJ" => "New Jersey",
  "NM" => "New Mexico",
  "NY" => "New York",
  "NC" => "North Carolina",
  "ND" => "North Dakota",
  "OH" => "Ohio",
  "OK" => "Oklahoma",
  "OR" => "Oregon",
  "PA" => "Pennsylvania",
  "PR" => "Puerto Rico",
  "RI" => "Rhode Island",
  "SC" => "South Carolina",
  "SD" => "South Dakota",
  "TN" => "Tennessee",
  "TX" => "Texas",
  "UT" => "Utah",
  "VT" => "Vermont",
  "VA" => "Virginia",
  "WA" => "Washington",
  "WV" => "West Virginia",
  "WI" => "Wisconsin",
  "WY" => "Wyoming"
}

# Initialize the Rails application.
Rails.application.initialize!
