
require_relative '../build.rb'
require_relative '../shared_flags.rb'
require 'fileutils'

$DEFAULT_SWIFT_VERSION = "5"

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
        $is_in_frost = true

        install
      end

      private

      def install

        working_directory = Pathname.new(File.join(config.project_root, "FrostPods"))

        FileUtils.mkdir_p(working_directory)

        gitignore_path = working_directory.join(".gitignore")

        unless gitignore_path.exist?
          File.write(gitignore_path, %{
build
out
Pods
})
        end

        sandbox = Sandbox.new(working_directory.join("Pods"))
        
        podfile = Pod::Podfile.from_file(File.join(config.project_root, "./Podfile"))

        lockfile_path = File.join(config.project_root, "./FrostPodfile.lock")      
        lockfile = Pod::Lockfile.from_file(Pathname.new(lockfile_path))

        # Before install

        installer = Installer.new(sandbox, podfile, lockfile)

        installer.repo_update = false
        installer.podfile.installation_options.integrate_targets = false
        installer.podfile.installation_options.warn_for_multiple_pod_sources = false
        installer.podfile.installation_options.deterministic_uuids = false
        installer.podfile.installation_options.generate_multiple_pod_projects = false
        installer.podfile.installation_options.incremental_installation = false

        # Install procedure manuall instead of using install!
        # No validation.

        installer.resolve_dependencies
        
        # Supports unknown swift-version pods
        installer.pod_targets.filter(&:uses_swift?).each do |target|
          if target.spec_swift_versions.empty?
            ## Redfine method
            ## For specifying swift-version in Pods project
            def target.spec_swift_versions
              [Pod::Version.new($DEFAULT_SWIFT_VERSION)]
            end
          end
        end

        installer.integrate

        # for now, calling methods of install inside to prevent validating.
        # Pod that no swift-version raises an error while validation
        generated_lockfile = installer.send(:generate_lockfile)
        
        generated_lockfile.write_to_disk(Pathname(lockfile_path))

        # After install

        targets = installer.pod_targets

        Pod::UI.puts "Target pods to create xcramework"
        $target_names.each do |name|
          Pod::UI.puts "  - 📦 #{name}"
        end

        targets.each do |target|

          unless $target_names.any? { |name| name.start_with?(target.name) }
            next
          end

          puts "📦 Build #{target.name}"
         
          # For Debugging before building
          generate_podspec_for_xcframework(
            target: target,
            xcframework_path: ""
          )  

          ## Prepare directory     
          pod_directory = working_directory.join("./GeneratedPods/#{target.root_spec.name}")   
                                         
          FileUtils.rm_rf(pod_directory)
          FileUtils.mkdir_p(pod_directory)
                  
          ## Build XCFramework
          configuration = "Release"
          xcframework_path = CocoapodsFrost.create_xcframewrok(
            output_directory: pod_directory,
            build_directory: working_directory.join("./build"),
            module_name: target.product_module_name,
            project_name: sandbox.project_path.realdirpath,
            scheme: target.label,
            configuration: configuration
          )    
        
          ## Generated podspec.json
          podspec = generate_podspec_for_xcframework(
            target: target,
            xcframework_path: Pathname(xcframework_path).relative_path_from(pod_directory)
          )                          

          ## Make a original podspec file
          File.write(pod_directory.join("original-podspec-#{target.name}.json"), target.root_spec.to_pretty_json)
                                    
          ## Make a podspec file
          File.write(pod_directory.join("#{podspec.name}.podspec.json"), podspec.to_pretty_json)
                  
          ## Copy license files  into the directory
          target.file_accessors.each do |a|
            FileUtils.cp(a.license, pod_directory)
          end

          Pod::UI.puts "Created #{pod_directory}"

        end
        
        Pod::UI.puts "✅ Frost completed"
        Pod::UI.puts "Next: pod install"

      end

    end
  end
end

# Returns attributes for podspec
def generate_podspec_for_xcframework(target:, xcframework_path:)

  podspec = target.root_spec.clone

  if podspec.subspecs.empty?
    podspec.attributes_hash.delete('source_files')

    podspec.attributes_hash["vendored_frameworks"] = ["#{xcframework_path}"]
  else

    ## Finds depedencies by specified subspecs
    using_subspecs = podspec
      .subspecs
      .filter { |s| 
        target.library_specs          
          .any? { |l| l.name == s.name }
      }

    ## Merge into one hash from all of dependencies
    dependencies_hash = podspec.attributes_hash["dependencies"] || {}
    frameworks = []

    using_subspecs.each do |spec|   
      
      ## Gathering dependencies without its subspec
      dependencies = spec.attributes_hash["dependencies"] || {}
      dependencies.delete_if { |key, _| 
        key.start_with?(podspec.name)
      }
      dependencies_hash = dependencies_hash.merge(dependencies)

      ## Gathering frameworks needs to link dynamically
      _frameworks = spec.attributes_hash["frameworks"]
      unless _frameworks.nil?
        if _frameworks.kind_of?(Array)
          frameworks += _frameworks
        else
          frameworks.push(_frameworks)
        end
      end

    end

    frameworks = frameworks.uniq
      
    podspec.attributes_hash["dependencies"] = dependencies_hash
    podspec.attributes_hash["frameworks"] = frameworks
    
    podspec.subspecs = []
    podspec.attributes_hash.delete("default_subspecs")

    podspec.attributes_hash["vendored_frameworks"] = ["#{xcframework_path}"]

  end

  return podspec
end