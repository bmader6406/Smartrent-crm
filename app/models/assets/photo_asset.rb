class PhotoAsset < Asset
  has_attached_file :file,
     :styles => {
       :small => "256",
       :medium => "512"
     },
     :storage => :s3,
     :processors => [:cropper],
     :s3_credentials => "#{Rails.root.to_s}/config/s3.yml",
     :path => ":class/:attachment/:id/:style/:filename",
     :default_url => ""
     
   validates_attachment :file, 
     :presence => true,
     :size => {:less_than => 10.megabytes, :message => "file size must be less than 10 megabytes" },
     :content_type => {
       :content_type => ['image/pjpeg', 'image/jpeg', 'image/png', 'image/x-png', 'image/gif'],
       :message => "must be either a JPEG, PNG or GIF image"
     }
end