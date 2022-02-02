
require_relative '../build.rb'
require_relative '../shared_flags.rb'
require 'fileutils'
require 'concurrent'

$DEFAULT_SWIFT_VERSION = "5"

module Pod
  class Command
    class Frost < Command

      ##
      # Make it can access to the configuration
      # `config`
      include Pod::Config::Mixin

      self.summary = "Frost is a plugin for CocoaPods that creates XCFramework(for internal distribution) for speeding up build time."

      def self.options
        [
          # ["--sources=#{Pod::TrunkSource::TRUNK_REPO_URL}", 'The sources from which to update dependent pods. ' \
          #  'Multiple sources must be comma-delimited'],
          ['--update-pods=podName', 'Pods to exclude during update. Multiple pods must be comma-delimited'],
          # ['--clean-install', 'Ignore the contents of the project cache and force a full pod installation. This only ' \
          #  'applies to projects that have enabled incremental installation'],
        ].concat(super)
      end

      def initialize(argv)
        @pods_to_update = argv.option('update-pods', '').split(',')
        super
      end
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

        # makes .gitignore file in FrostPods
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

        installer.repo_update = @pods_to_update.any?
        installer.update = {
          :pods => @pods_to_update
        }

        installer.podfile.installation_options.integrate_targets = false
        installer.podfile.installation_options.warn_for_multiple_pod_sources = false
        installer.podfile.installation_options.deterministic_uuids = false
        installer.podfile.installation_options.generate_multiple_pod_projects = false
        installer.podfile.installation_options.incremental_installation = false

        # Install procedure manuall instead of using install!
        # No validation.
        
        installer.prepare
        installer.resolve_dependencies
        installer.download_dependencies
                
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

        $target_names = $target_names.uniq

        targets = installer
          .pod_targets          
          .select { |target|
            $target_names.any? { |name| name.start_with?(target.name) }
          } 
          
        # validate
        targets.each { |target| 

          hasBundle = !target.resource_paths.filter { |key, value| !value.empty? }.empty?

          # if hasBundle
          #   puts "#{pod.name} has bundle"
          #   pod.resource_paths.each { |key, value|
          #     puts "  #{value}"
          #   }
          # end

          if hasBundle 
            raise "[#{target.name}] Currently not supported building pod which includes resources."
          end
        }
          
        log_targets(targets, $target_names)
        
        FileUtils.rm_rf(working_directory.join("GeneratedPods"))

        pool = Concurrent::FixedThreadPool.new(4)

        tasks = targets.select { |t| t.should_build? }.map { |target|        
          Concurrent::Promises.delay_on(pool) {
            build(
              working_directory: working_directory,
              xcodeproject_path: sandbox.project_path.realdirpath,
              target: target
            )
          }                    
        }

        Pod::UI.puts "🚜 Start building..."

        # TODO: throttle number of threads
        Concurrent::Promises.zip(*tasks).value!
        
        Pod::UI.puts "🚀 Frost completed"
        Pod::UI.puts "Next: pod install"

      end

    end
  end
end

def build(
  working_directory:,
  xcodeproject_path:,
  target:
)

  logs = []
         
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

  build_logs = []

  xcframework_path = CocoapodsFrost.create_xcframewrok(
    output_directory: pod_directory,
    build_directory: working_directory.join("./build"),
    module_name: target.product_module_name,
    project_name: xcodeproject_path,
    scheme: target.label,
    configuration: configuration,
    logs: build_logs
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
    FileUtils.cp(a.license, pod_directory) if File.exist?(a.license)
  end

  logs.push("Created #{pod_directory}")

  Pod::UI.puts "#{logs.join("\n")}\n#{build_logs.map { |s| "  #{s}"}.join("\n")}"

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

def log_targets(targets, target_names)
  Pod::UI.puts "Target graph to create xcramework."
  Pod::UI.puts "🗞 means building from source. specify `frost_pod <name>` to create xcframework"
  targets.each { |t|

    dependencies = []
              
    def print_pods(array, pod)
      array.push(pod.name)           
      pod.dependent_targets.each { |d|
        print_pods(array, d)
      }
    end

    t.dependent_targets.each { |d|
      print_pods(dependencies, d)
    }
  
    dependencies = dependencies.uniq

    if t.should_build?
      Pod::UI.puts "📦 #{t.name}"
    else
      Pod::UI.puts "🎯 #{t.name} (this is an aggregate target, not to build)"
    end    
    Pod::UI.puts dependencies
      .map { |d|
        if target_names.any? { |name| name.start_with?(d) } 
          "  📦 #{d}"
        else
          "  🗞 #{d}"
        end
      }
      .join("\n")
  }
end