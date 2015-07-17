# gmail setting
# - converstion view: off

Mail.defaults do
  retriever_method :imap, { :address             => "imap.googlemail.com",
                            :port                => 993,
                            :user_name           => OPS_U,
                            :password            => OPS_P,
                            :enable_ssl          => true }
end