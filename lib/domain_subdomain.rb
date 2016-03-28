class DomainSubdomain
  def self.matches?(request)
    # pp ">>>>>>> request.host: #{request.host}"
    # the system will redirect the user to smartrent engine if subdomain is not in the app_domains
    # Or domain name is bozzuto.com
    
    if request.subdomain.present?
      app_domains = ["crm", "crm2", "crm-beta", "crm-live", "crm-dev"]
      return !app_domains.include?(request.subdomain)
      
    else
      return !["bozzuto.com"].include?(request.host)
    end
  end
end