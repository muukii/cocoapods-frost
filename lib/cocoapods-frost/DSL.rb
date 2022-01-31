require_relative './shared_flags.rb'

module Pod 
  class Podfile
    module DSL

      def frost_pod(name, *args)
        
        if $is_in_frost 
          args.each do |element|
            element.delete(:path) unless element[:path].nil?
          end        
        end
        pod(name, *args)
      end

    end
  end
end