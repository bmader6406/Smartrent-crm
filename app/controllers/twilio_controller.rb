# How twilio work?
# Short answer: magic butterflies.
# 
# Longer answer: Twilio isn't actually controlling a phone line directly from the browser. 
# There are a few layers between the browser and your phone. For outbound calls it works something like this:
# 
#     - Web Browser makes requests to...
#     - Back-end server technology (like PHP/ASP.NET/Rails/etc) makes requests to...
#     - Twilio REST API which dispatches...
#     - Magic butterflies to connect the call to...
#     - The person being called using...
#     - A URL you specify to direct the call using simple TwiML/XML
# 
# For inbound calls, it works pretty much in reverse:
# 
#     - A caller is connected to...
#     - Magic butterflies which do their thing and make...
#     - A HTTP POST request made to the a URL you specify using a...
#     - Back-end server technology that returns TwiML/XML back to Twilio
#     - Magic butterflies handle translating TwiML into actions sent back to the caller
# 
# In each case, the magic butterflies represent a scalable cloud communications infrastructure that
# handles all the complicated telephony stuff required to send/receive calls and text messages so that you don't
# have to worry about anything beyond GET, POST and XML, the stuff you're used to working with every day as a web developer.
#


#require 'twilio-ruby'

class TwilioController < ApplicationController
  # Before we allow the incoming request to connect, verify that it is a Twilio request
  before_action :authenticate_twilio_request, :only => [:p2p_connect, :p2p_fallback, :p2p_status, :w2p_connect, :w2p_fallback2, :w2p_status]

  layout false

  def usage
    @client = Twilio::REST::Client.new TWILIO_SID, TWILIO_TOKEN
    @usage = @client.account.usage.records.list({
      :start_date => Time.now.beginning_of_month.to_date.to_s,
      :end_date => Time.now.end_of_month.to_date.to_s
    })
    @total = @usage.detect{|u| u.category == "totalprice" }
  end

  #phone2phone
  def p2p_connect
    pp "p2p_connect: #{Time.now}", params
    call = Call.find_by_origin_id(params[:CallSid])
    response = Twilio::TwiML::Response.new do |r|
      r.Dial call.to
    end

    render text: response.text
  end

  def p2p_status
    pp "p2p_status: #{Time.now}", params
    call = Call.find_by_origin_id(params[:CallSid])
    call.update_attributes({
      :recording_duration => params[:CallDuration],
      :recording_url => params[:RecordingUrl]
    })
    render text: "Ok"
  end

  def p2p_fallback
    pp "p2p_fallback: #{Time.now}", params
  end
  
  private
  
    # Authenticate that all requests to our public-facing TwiML pages are
    # coming from Twilio. Adapted from the example at 
    # http://twilio-ruby.readthedocs.org/en/latest/usage/validation.html
    # Read more on Twilio Security at https://www.twilio.com/docs/security
    
    def authenticate_twilio_request
      twilio_signature = request.headers['HTTP_X_TWILIO_SIGNATURE']

      # Helper from twilio-ruby to validate requests. 
      @validator = Twilio::Util::RequestValidator.new(TWILIO_TOKEN)

      # the POST variables attached to the request (eg "From", "To")
      # Twilio requests only accept lowercase letters. So scrub here:
      post_vars = params.reject {|k, v| k.downcase == k}

      is_twilio_req = @validator.validate(request.url, post_vars, twilio_signature)

      if !is_twilio_req
        render :xml => (Twilio::TwiML::Response.new {|r| r.Hangup}).text, :status => :unauthorized
        false
      end
    end
end