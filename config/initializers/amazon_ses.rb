ActionMailer::Base.add_delivery_method :ses, AWS::SES::Base,
  :access_key_id     => AWS_KEY,
  :secret_access_key => AWS_SECRET