class Asset < ActiveRecord::Base

  belongs_to :property
  belongs_to :comment
  
  validates :property_id, :presence => true
  
  serialize :dimensions
  
  before_save :extract_dimensions
  before_save :maintain_extension
  
  def image?
    file_content_type =~ %r{^(image|(x-)?application)/(bmp|gif|jpeg|jpg|pjpeg|png|x-png|x-icon)$}
  end
  
  def cropping? #must be defined, otherwise the cropper will raise error
    false
  end
  
  def to_jq_upload
    {
      :id => id.to_s,
      :name => file_file_name,
      :size => file_file_size,
      :thumbnailUrl => self.kind_of?(PhotoAsset) ? file.url(:small) : nil,
      :url => file.url(:original)
    }
  end
  
  def to_file_name
    File.basename(file_file_name, File.extname(file_file_name))
  end

  def to_file_type
    file_content_type.to_s.gsub(/image|x-|\//, '').upcase
  end

  def to_dimensions
    dimensions ? dimensions.join('x') : nil
  end

  def to_thumbnail_style
    width = to_dimensions.to_s.split("x").first.to_i
    width > 128 ? :small : :original
  end
  
  private
    # Retrieves dimensions for image assets
    # @note Do this after resize operations to account for auto-orientation.
    def extract_dimensions
      return unless image?
      tempfile = file.queued_for_write[:original]
      unless tempfile.nil?
        geometry = Paperclip::Geometry.from_file(tempfile)
        self.dimensions = [geometry.width.to_i, geometry.height.to_i]
      end
    end
    
    def maintain_extension
      if file_file_name_was && file_file_name_changed?
        ext_was = File.extname(file_file_name_was)
        ext = File.extname(file_file_name)

        if ext.blank? && ext_was
          self.file_file_name +=  ext_was
        end
      end
    end
    
end