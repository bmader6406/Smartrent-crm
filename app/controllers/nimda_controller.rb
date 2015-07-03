class NimdaController < ApplicationController
  before_action :require_ssl

  http_basic_authenticate_with :name => NIMDA_U, :password => NIMDA_P
  
  layout "nimda"
  
end
