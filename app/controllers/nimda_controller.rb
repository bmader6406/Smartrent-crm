require 'net/ftp'

class NimdaController < ApplicationController
  before_action :require_user
  before_action :require_admin
  before_action :set_page_title
  before_action :set_residents, only: [:load_export_residents]
  before_action :export_resident_params, only: [:load_export_residents]

  layout "application"
  
  def show
    redirect_to nimda_templates_url
  end
  
  def units
    @import = Import.find_or_initialize_by(type: "load_units_one_time")
    @import.save if @import.new_record?
    
    @daily_import = Import.find_or_initialize_by(type: "load_units_weekly")
    @daily_import.save if @daily_import.new_record?
  end
  
  def load_units
    import = Import.find_by_type(params[:type])
    import.update_attributes(:ftp_setting => params[:ftp_setting], :active => params[:active])
    
    Resque.enqueue(UnitLoader, Time.now, import.id) if params[:active] == "1"
    
    render :json => {:success => true}
  end
  
  def yardi
    @import = Import.find_or_initialize_by(type: "load_yardi_one_time")
    @import.save if @import.new_record?
    
    @daily_import = Import.find_or_initialize_by(type: "load_yardi_daily")
    @daily_import.save if @daily_import.new_record?
  end
  
  def load_yardi
    import = Import.find_by_type(params[:type])
    import.update_attributes(:ftp_setting => params[:ftp_setting], :field_map => params[:field_map], :active => params[:active])
    
    Resque.enqueue(YardiLoader, Time.now, import.id) if params[:active] == "1"
    
    render :json => {:success => true}
  end
  
  def non_yardi_master
    @daily_import = Import.find_or_initialize_by(type: "load_non_yardi_master_daily")
    @daily_import.save if @daily_import.new_record?
  end
  

  def xml_property_importer
    @daily_import = Import.find_or_initialize_by(type: "load_xml_property_importer")
    @daily_import.save if @daily_import.new_record?
  end


  def load_xml_property_importer
    import = Import.find_by_type(params[:type])
    import.update_attributes(:ftp_setting => params[:ftp_setting], :field_map => params[:field_map], :active => params[:active])
    Resque.enqueue(XmlPropertyImporter, Time.now, import.id) if params[:active] == "1"
    
    render :json => {:success => true}
  end


  def load_non_yardi_master
    import = Import.find_by_type(params[:type])
    import.update_attributes(:ftp_setting => params[:ftp_setting], :field_map => params[:field_map], :active => params[:active])
    
    Resque.enqueue(NonYardiMasterLoader, Time.now, import.id) if params[:active] == "1"
    
    render :json => {:success => true}
  end
  
  
  # # disabled on 2017-Jan-20
  def non_yardi
    @imports = Import.where(type: "load_non_yardi_daily").all # it is supposed to run weekly but we check for the feed daily, run the import if any
    
    if @imports.empty?
      import = Import.find_or_initialize_by(type: "load_non_yardi_daily")
      import.save if import.new_record?
      
      @imports = [import]
    end
  end
  
  def create_non_yardi
    Import.create(type: "load_non_yardi_daily")
    
    render :json => {:success => true}
  end
  
  def delete_non_yardi
    Import.find(params[:id]).update_attribute(:deleted_at, Time.now)
    
    render :json => {:success => true}
  end
  
  def load_non_yardi
    import = Import.find(params[:id])
    import.update_attributes(:ftp_setting => params[:ftp_setting], :field_map => params[:field_map], :property_map => params[:property_map], :active => params[:active])
    
    Resque.enqueue(NonYardiLoader, Time.now, import.id) if params[:active] == "1"
    
    render :json => {:success => true}
  end
  
  
  def test_ftp
    begin
      ftp = Net::FTP.new()
      ftp.passive = true
      ftp.connect(params[:ftp_setting][:host])
      ftp.login(params[:ftp_setting][:username], params[:ftp_setting][:password])
      ftp.close

      render :json => {:success => true}
      
    rescue Exception => e
      pp "ftp test ERROR: ", e
      
      render :json => {:success => false}
    end
  end

  def export_residents
  end

  def load_export_residents
    file_name = "residents-#{export_resident_params[:property_name]}-#{Date.today}.csv"    
    column_names = ["Current Property Name", "Current Property State", "SmartRent Property?", "Current Property ZipCode",
   "Resident Email", "Rommate Status", "First Name", "Last Name", "SmartRent Status", "Resident Status", "Gender"]
    result = CSV.generate(headers: true) do |csv|
      csv << column_names
      file_name = "residents-#{Date.today}.csv"
      if @residents.count > 0
        @residents.each do |sr|
         if (sr.smartrent_status == export_resident_params[:smartrent_status] and !sr.get_csv.nil? )
          csv << sr.get_csv
         end
        end
      end
    end
    send_data result, :type => 'text/csv;', :disposition => "filename= #{file_name}"
  end

   protected

   def set_page_title
      Time.zone = "Eastern Time (US & Canada)" #temp
      
      @page_title = "CRM - Admin"
    end

    private

    def set_residents
     @residents = []
     property_list = Property.where("state = ? and name = ?", export_resident_params[:property_state], export_resident_params[:property_name]).collect(&:id)
     Smartrent::ResidentProperty.where(:property_id => property_list).each do |sr|
        @residents << sr.resident
     end 
     @residents = @residents.uniq.compact
    end

  def export_resident_params
    params.permit(:property_name, :property_state, :smartrent_status)
  end

end
