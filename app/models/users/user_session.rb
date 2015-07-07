class UserSession < Authlogic::Session::Base
  allow_http_basic_auth false #fix redirect loop if basic authentication session of nimda is existing

  self.last_request_at_threshold = 1.hour  #not update the user record on every request
end