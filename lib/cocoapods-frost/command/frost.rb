
require_relative '../build.rb'
require_relative '../shared_flags.rb'

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

        $is_in_frost = true
        install
      end

      private

      def install

        working_directory = Pathname.new(File.join(config.sandbox_root, "Frost"))

        sandbox = Sandbox.new(working_directory)
        
        # podfile = Pod::Podfile.new(File.join(config.sandbox_root, "../Podfile"))
        podfile = Pod::Podfile.from_file(File.join(config.sandbox_root, "../Podfile"))

        # analyzer = Pod::Installer::Analyzer.new(sandbox, podfile)
        # p analyzer.analyze

        lockfile_path = File.join(config.sandbox_root, "../Podfile.lock")
      
        lockfile = Pod::Lockfile.from_file(Pathname.new(lockfile_path))

        # Before install

        installer = Installer.new(sandbox, podfile, lockfile)

        installer.repo_update = false
        installer.podfile.installation_options.integrate_targets = false
        installer.podfile.installation_options.warn_for_multiple_pod_sources = false
        installer.podfile.installation_options.deterministic_uuids = false
        installer.podfile.installation_options.generate_multiple_pod_projects = false
        installer.podfile.installation_options.incremental_installation = false

        installer.install!

        # After install

        targets = installer.pod_targets

        targets.each do |target|

          puts "📦 Build #{target.name}"

          copied_root_spec = target.root_spec.clone

          # generate_podspec_for_xcframework(
          #   podspec: copied_root_spec,
          #   xcframework_path: ""
          # )

          # p CocoapodsFrost.xcodebuild

          configuration = "Release"

          xcframework_path = CocoapodsFrost.create_xcframewrok(
            output_directory: working_directory.join("./out"),
            build_directory: working_directory.join("./build"),
            module_name: target.product_module_name,
            project_name: sandbox.project_path.realdirpath,
            scheme: target.label,
            configuration: configuration
          )        

          podspec = generate_podspec_for_xcframework(
            podspec: copied_root_spec,
            xcframework_path: Pathname(xcframework_path).relative_path_from(working_directory.join("./out"))
          )        
        
          podspec_path = working_directory.join("./out/#{podspec.name}.podspec.json")
          File.write(podspec_path, podspec.to_pretty_json)
          Pod::UI.puts "Created #{podspec_path}"

        end
        
        Pod::UI.puts "✅ Frost completed"

      end

    end
  end
end

# Returns attributes for podspec
def generate_podspec_for_xcframework(podspec:, xcframework_path:)

  if podspec.subspecs.empty?
    podspec.attributes_hash.delete('source_files')

    # podspec.attributes_hash["ios"] = {
    #   "preserve_paths": "#{xcframework_path}",
    #   "vendored_frameworks": "#{xcframework_path}"
    # }
    podspec.attributes_hash["vendored_frameworks"] = ["#{xcframework_path}"]
  else

  end

  podspec
end