
module Pod
  class Command
    class Frost < Command

      ##
      # Make it can access to the configuration
      # `config`
      include Pod::Config::Mixin

      self.summary = "Hello"

      ##
      # The entrypoint of this command
      def run
        puts "hi"

        install
      end

      private

      def install

        p config
      end

    end
  end
end