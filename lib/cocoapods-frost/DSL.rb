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
          path = "./Pods/Frost/out/#{name}.podspec.json"
          if File.exist?(path) 
            Pod::UI.puts "📦 #{name} - Found generated podspec."
            pod(name, *args, path: path)
          else
            Pod::UI.warn "📦 #{name} - Not Found generated podspec."
            pod(name, *args)
          end
        end        
      end

    end
  end
end