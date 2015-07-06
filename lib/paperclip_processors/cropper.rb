module Paperclip
  class Cropper < Thumbnail
  
    def transformation_command
      target = @attachment.instance
      if target.cropping?        
        scale, crop = @current_geometry.transformation_to(@target_geometry, crop?)        
        trans = []
        trans << "-crop" << %["#{target.crop_w.to_i}x#{target.crop_h.to_i}+#{target.crop_x.to_i}+#{target.crop_y.to_i}"] #<< "+repage"
        trans << "-resize" << %["#{scale}"] unless scale.nil? || scale.empty?        
        trans
      else
        super
      end
    end
    
    #supported animated gif by overidding the make method (remove [0])
    
    # Performs the conversion of the +file+ into a thumbnail. Returns the Tempfile
    # that contains the new image.
    def make
      src = @file
      dst = Tempfile.new([@basename, @format ? ".#{@format}" : ''])
      dst.binmode

      begin
        parameters = []
        parameters << source_file_options
        parameters << ":source"
        parameters << transformation_command
        parameters << convert_options
        parameters << ":dest"

        parameters = parameters.flatten.compact.join(" ").strip.squeeze(" ")

        success = Paperclip.run("convert", parameters, :source => "#{File.expand_path(src.path)}", :dest => File.expand_path(dst.path))
      rescue Exception => e
        error_details = "#{e.class}: #{e}"
        error_details += "\n#{e.backtrace.join("\n")}" if e.backtrace

        p "ERROR: #{error_details}"
        
        raise "There was an error processing the thumbnail for #{@basename}" if @whiny
      end

      dst
    end
    
  end
end
