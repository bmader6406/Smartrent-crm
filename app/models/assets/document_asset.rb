class DocumentAsset < Asset
  has_attached_file :file,
    :storage => :s3,
    :s3_protocol => :https,
    :s3_credentials => "#{Rails.root.to_s}/config/s3.yml",
    :path => ":class/:attachment/:id/:filename", #:org is paperclip interpolation.
    :default_url => ""

  validates_attachment :file, 
    :presence => true,
    :size => {:less_than => 10.megabytes, :message => "file size must be less than 10 megabytes" },
    :content_type => {
      :content_type => [
        'application/pdf', 'text/plain',
        'application/msword','applicationvnd.ms-word','application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'application/msexcel','application/vnd.ms-excel','application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'application/mspowerpoint','application/vnd.ms-powerpoint','application/vnd.openxmlformats-officedocument.presentationml.presentation'
      ],
      :message => "must be either a PDF, DOC, DOCX, XLS, XLSX, PPT, PPTX or TXT file"
    }
end