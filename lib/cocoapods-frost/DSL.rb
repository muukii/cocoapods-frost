require_relative './shared_flags.rb'

module Pod 
  class Podfile
    module DSL

      def frost_pod(name, *args)
     
        # use_binary = false
        # args.each do |element|            
        #   unless element[:use_binary]
        #     element.delete(:use_binary) 
        #     use_binary = true
        #   end
        # end   

        $target_names.push(name)

        if $is_in_frost 
          # TODO: raises an error path pointing generated podspec.
          pod(name, *args)
        else

          regex_for_subspec_specifier = /\/.*/          
          unless regex_for_subspec_specifier.match(name).nil?
            Pod::UI.puts "[Frost] #{name} Specifying subspecs converts to whole installing."
            name = name.gsub(regex_for_subspec_specifier, "")
          end

          pod(name, *args, path: "./Pods/Frost/GeneratedPods/#{name}")
        end        
      end

    end
  end
end