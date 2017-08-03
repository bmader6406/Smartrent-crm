class SanitizeXss
    def self.sanitize(model_value,exclude_list=[])
        model_value.attributes.each do |key, value|
          puts "1-key:#{key}:value:#{model_value[key]}"
          unless exclude_list.include?(key)
            model_value[key] = ActionView::Base.full_sanitizer.sanitize(model_value[key]) if model_value[key].is_a? String
            puts "2-key:#{key}:value:#{model_value[key]}"
            model_value[key] = HTMLEntities.new.decode(model_value[key])
            model_value[key] = model_value[key].strip if model_value[key].respond_to?("strip")
          end
          puts "3-key:#{key}:value:#{model_value[key]}"
        end
        model_value
    end
end