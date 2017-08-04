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

# Google file picker ( https://console.developers.google.com/apis/credentials?project=bozzuto-crm-175613 - TN)
GOOGLE_KEY = "AIzaSyDo8rbG0auod1g86VP3IojvW6MpnAmpKpo"
GOOGLE_APP_ID = "606078691596-vhc378gobk2h25lp25h4o8s98tbck5p5.apps.googleusercontent.com"
GOOGLE_SECRET = "M1aJEvdugR-RVZLQl97-A1uB"


# Dropbox file picker (TN)
DROPBOX_KEY = "uz8siqge13citwb"

# Todd's account
TWILIO_SID = "AC5a31d3785fa57e63e37e04c20b5fd680"
TWILIO_TOKEN = "f99c23265c3a1c99249d83e23394e17e"
TWILIO_NUMBER = "+1 240-245-2373"

TWILIO_P2P_SID = Rails.env.production? ? "APcdc45777f146399459e86d1c8d4ac982" : "AP72efd2192c606511cdbca4870bb47a6c"

# email config
EMAIL_DOMAIN = "bozzuto.com"
ADMIN_EMAIL = "tn+admin@#{EMAIL_DOMAIN}"
HELP_EMAIL = "crm-help@#{EMAIL_DOMAIN}"

SMARTRENT_EMAIL = "smartrent@bozzuto.com"

# Resident stream - email conversation
CONVO_EMAIL = "bozzuto_conversation@#{EMAIL_DOMAIN}"
CONVO_PWD = "B0zzut0!@#conv"

# SES monitor, notification email sender address
OPS_EMAIL = "bozzuto_ops@#{EMAIL_DOMAIN}"
OPS_PWD = "B0zzut0!@#ops"

# AWS SES & S3
AWS_KEY = "AKIAICJX5ULNO7BJ3IYA"
AWS_SECRET = "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"


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
