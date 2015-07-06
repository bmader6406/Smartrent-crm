class DownloadsController < ApplicationController
  
  def show
    file_name = params[:id]
    path = "#{TMP_DIR}#{file_name}"
    
    #remove the random id
    friendly_name = file_name.split("_").slice(1, 100).join("_")
    
    pp ">>>", path
    
    if File.exist?(path)
      size = (File.size(path).to_f / 2**20).round(2)
      
      if size < 10
        execute_at = Time.now + 2.minutes
        
      elsif size < 20
        execute_at = Time.now + 5.minutes
        
      elsif size < 50
        execute_at = Time.now + 15.minutes
        
      elsif size < 100
        execute_at = Time.now + 30.minutes
        
      else
        execute_at = Time.now + 1.hour
      end
      
      Resque.enqueue_at(execute_at, DownloadCleaner, file_name)
      
      send_file path, :filename => friendly_name
      
    else
      render :text => "File Not Found! You may have downloaded the file or the download link may have expired."
      
    end
  end
end