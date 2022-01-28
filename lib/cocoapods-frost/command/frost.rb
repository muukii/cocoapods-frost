
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

        p config.sandbox_root

        sandbox = Sandbox.new(File.join(config.sandbox_root, "Frost"))
        
        # podfile = Pod::Podfile.new(File.join(config.sandbox_root, "../Podfile"))
        podfile = Pod::Podfile.from_file(File.join(config.sandbox_root, "../Podfile"))

        installer = Installer.new(sandbox, podfile)

        installer.repo_update = false
        installer.podfile.installation_options.integrate_targets = false
        installer.podfile.installation_options.warn_for_multiple_pod_sources = false
        installer.podfile.installation_options.deterministic_uuids = false

        installer.install!
      end

    end
  end
end