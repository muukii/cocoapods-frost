puts 'Load DSL'
module Pod 
  class Podfile
    module DSL

      def frost_pod(name, *args)
        pod(name, *args)
      end

    end
  end
end