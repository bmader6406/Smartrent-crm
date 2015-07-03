AWS::SES::SendEmail.class_eval do
  #TN: made bbc work with ses
  def send_raw_email(mail, args = {})
    message = mail.is_a?(Hash) ? Mail.new(mail) : mail
    package = { 'RawMessage.Data' => Base64::encode64(message.to_s) }
    package['Source'] = args[:from] if args[:from]
    package['Source'] = args[:source] if args[:source]
    
    # Extract the list of recipients based on arguments or mail headers
    destinations = []
    if args[:destinations]
      destinations.concat args[:destinations].to_a
    elsif args[:to]
      destinations.concat args[:to].to_a
    else
      destinations.concat mail.to.to_a
      destinations.concat mail.cc.to_a
      destinations.concat mail.bcc.to_a
    end
    add_array_to_hash!(package, 'Destinations', destinations) if destinations.length > 0
    
    result = request('SendRawEmail', package)

    message.message_id = "#{result.parsed['SendRawEmailResult']['MessageId']}@email.amazonses.com"
    
    result
  end
  
  alias :deliver! :send_raw_email
  alias :deliver  :send_raw_email
    
end
