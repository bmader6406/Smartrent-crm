class AssetsController < ApplicationController
  before_action :require_user
  before_action :set_property
  before_action :set_asset, :except => [:index, :new, :create, :import]
  before_action :set_page_title  

  def index
    @assets = @property.assets
    @assets = @assets.where(["file_file_name LIKE ?", "%#{params[:search]}%"]) if !params[:search].blank?

    @assets = @assets.paginate(:page => params[:page], :per_page => 12)
  end

  def create
    assets = []

    params[:files].each do |file|
      asset = asset_clzz(file.original_filename).new(:file => file, :property => @page)
      assets << asset if asset.save
    end

    render :json => {:files => assets.collect{|a| a.to_jq_upload }} 
  end
  
  def import
    assets = []

    params[:urls].each do |url|
      next if url.blank?
      assets << import_library_asset(url, params[:source], params[:access_token])
    end

    render :json => {:files => assets.collect{|a| a.to_jq_upload }} 
  end

  def update

    if asset_params[:file] #from aviary
      asset_params[:file_file_name] = @asset.file_file_name
      asset_params[:file] = URI.parse(asset_params[:file])
    end

    @asset.update_attributes(asset_params)

    render :json => {:success => true}
  end

  def destroy
    @asset.destroy
  end

  #########

  def select
    select_asset(@asset)
  end

  protected
    def asset_params
      params.require(:asset).permit!
    end
    
    def set_property
      if params[:property_id] == "-1" && session[:editing_campaign_id] #nimda page
        @property = Property.find_or_initialize_by(id: -1)
        @property.save(:validate => false) if @property.new_record?

      else
        @property = current_user.managed_properties.find(params[:property_id])

        @campaigns = Campaign.for_page(@property)

        Time.zone = @property.setting.time_zone
      end

    end

    def set_asset
      @asset = @property.assets.find(params[:id])
    end

    def set_page_title
      if action_name == "edit"
        @page_title = "CRM - #{@property.name} - Edit Image"
      else
        @page_title = "CRM - #{@property.name} - Media Library"
      end
    end

    def asset_clzz(file_name)
      [".doc",".docx",".pdf",".xls",".xlsx", ".ppt", ".pptx", ".txt"].include?(File.extname(file_name).to_s.downcase) ? DocumentAsset : PhotoAsset
    end

    def import_library_asset(url, source, auth_token = nil)
      url, title = url.split("___", 2)

      if !auth_token.blank?
        attrs = {:file => open(url, {"Authorization" => "OAuth #{auth_token}"}), :file_file_name => title, :property => @page}
        asset_clzz(title).create(attrs)

      else
        attrs = {:file => URI.parse(url), :property => @page}

        attrs[:file_file_name] = title if title #for file from aviary

        if !title
          title = File.basename(url)
          title = title.split('?').first
        end

        asset_clzz(title).create(attrs)

      end
    end

    def select_asset(asset)
      return false if asset.new_record?
      return false if params[:comment_id].blank? #media library
      
      hash = {:file => asset.file, :comment_id => params[:comment_id], :property => @page}

      case params[:target]
        when "photo"
          @selected_asset = PhotoAsset.new(hash)
          @selected_asset.save
          
        when "document"
          @selected_asset = DocumentAsset.new(hash)
          @selected_asset.save
      end
    end
end