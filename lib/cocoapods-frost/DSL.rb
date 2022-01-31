require_relative './shared_flags.rb'

module Pod 
  class Podfile
    module DSL

      def frost_pod(name, *args)
        puts "Frost =>", $is_in_frost ? "true" : "false"
        pod(name, *args)
      end

    end
  end
end