# encoding: utf-8

class ConversationMonitor
  extend Resque::Plugins::Retry
  @retry_limit = RETRY_LIMIT
  @retry_delay = RETRY_DELAY

  def self.queue
    :crm_medium
  end

  def self.perform
    Mail::Configuration.instance.retriever_method(:imap, {
      :address             => "imap.googlemail.com",
      :port                => 993,
      :user_name           => CONVO_EMAIL,
      :password            => CONVO_PWD,
      :enable_ssl          => true 
    })
    
    total = 0 
    
    Mail.find_and_delete({:what => :last, :count => 50, :order => :desc}) { |m|
      total += 1
    
      begin
        from = m.from.first.to_s
        to = m.to.first.to_s
        cc = m.cc.kind_of?(Array) ? m.cc.join(", ") : nil
        
        token = to.gsub('conversation+rep', '').gsub('@hy.ly', '')
        subject = m.subject.to_s
        message = m.html_part.body.to_s
        text_message = m.text_part.body.to_s rescue ""
        
        if !text_message.blank?
          message = EmailReplyParser.parse_reply(text_message).gsub(/(?:\n\r?|\r\n?)/, '<br/>') # remove reply text
        end
        
        email = Email.find_by_token(token)

        if email && email.comment && email.comment.resident 
          comment = Comment.new({
            :type => "email",
            :property_id => email.comment.property_id,
            :unit_id => email.comment.unit_id,
            :resident_id => email.comment.resident_id,
            :parent => email.comment,
            :author_id => email.comment.resident.id,
            :author_type => email.comment.resident.class.to_s
          })
          
          comment.build_email({
            :subject => subject,
            :message => message,
            :from => from,
            :to => email.from,
            :cc => cc,
            :message_id => m.message_id
          })

          comment.save
          
          email.comment.resident.activities.create({
            :property_id => comment.property_id,
            :unit_id => comment.unit_id,
            :action => comment.type,
            :subject_id => comment.id,
            :subject_type => comment.class.to_s
          })
        else
          
          m.skip_deletion
        end

        pp "#{total}: #{subject}, #{from}, #{to}, #{m.message_id}, #{message}"
      
      rescue Exception => e
      
        m.skip_deletion
      
        error_details = "#{e.class}: #{e}"
        error_details += "\n#{e.backtrace.join("\n")}" if e.backtrace

        p "ERROR: #{error_details}"
      end
    }
    
  end

end