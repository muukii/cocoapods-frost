
module CocoapodsFrost 

  # Returns a path to created xcframework
  def self.create_xcframewrok(
    output_directory:,
    build_directory:,
    module_name:,
    project_name:,
    scheme:,
    configuration:,
    logs:
  )
    
    logs.push "🚜 #{module_name} -> #{configuration} Building into #{output_directory}"

    options = []

    options.push("ENABLE_BITCODE=YES")
    options.push("BITCODE_GENERATION_MODE=bitcode")
    options.push("OTHER_CFLAGS=-fembed-bitcode")    
    options.push("BUILD_LIBRARY_FOR_DISTRIBUTION=false")
    options.push("SKIP_INSTALL=NO")
    options.push("DEBUG_INFORMATION_FORMAT=dwarf-with-dsym")
    options.push("ONLY_ACTIVE_ARCH=NO")

    # FileUtils.mkdir_p

    archive_path_ios = File.join(build_directory, "#{module_name}/ios.xcarchive")
    archive_path_ios_simulator = File.join(build_directory, "#{module_name}/ios-simulator.xcarchive")

    xcodebuild(
      projectName: project_name,
      scheme: scheme,
      configuration: configuration,
      destination: "generic/platform=iOS",
      sdk: "iphoneos",
      archivePath: archive_path_ios,
      derivedDataPath: File.join(build_directory, "#{module_name}"),
      otherOptions: options
    )
    logs.push "[iOS] Build succeeded"

    xcodebuild(
      projectName: project_name,
      scheme: scheme,
      configuration: configuration,
      destination: "generic/platform=iOS Simulator",
      sdk: "iphonesimulator",
      archivePath: archive_path_ios_simulator,
      derivedDataPath: File.join(build_directory, "#{module_name}"),
      otherOptions: options
    )
    logs.push "[iOS Simulator] Build succeeded"

    # https://github.com/madsolar8582/SLRNetworkMonitor/blob/e415fc6399aa164ab8b147a6476630b2418d1d75/release.sh#L73
  
    args = []

    instance_eval do
      bitcodePaths = Dir.glob(File.join(archive_path_ios, "/**/*.bcsymbolmap"))

      archivePath = archive_path_ios

      dSYMPath = "#{archivePath}/dSYMs/#{module_name}.framework.dSYM"

      args.push("-framework \"#{archivePath}/Products/Library/Frameworks/#{module_name}.framework\"")

      if Dir.exist? dSYMPath
        args.push("-debug-symbols \"#{archivePath}/dSYMs/#{module_name}.framework.dSYM\"")
      end

      args += bitcodePaths.map { |e|
        "-debug-symbols \"#{e}\""
      }
    end

    instance_eval do
      archivePath = archive_path_ios_simulator
      dSYMPath = "#{archivePath}/dSYMs/#{module_name}.framework.dSYM"

      args.push("-framework \"#{archivePath}/Products/Library/Frameworks/#{module_name}.framework\"")
      if Dir.exist? dSYMPath
        args.push("-debug-symbols \"#{archivePath}/dSYMs/#{module_name}.framework.dSYM\"")
      end
    end

    output = File.join(output_directory, "#{module_name}.xcframework")

    args.push("-output #{output}")

    if File.exist?(output)
      FileUtils.rm_rf(output)
    end

    command = "xcodebuild -create-xcframework -allow-internal-distribution #{args.join(" \\\n")}"

    # puts command

    log = `#{command}`
  
    if File.exist? output
      logs.push "✅ Making XCFramework succeeded: #{output}\n"
    else      
      logs.push "❌ Making XCFramework failed\n"
      logs.push log
    end

    output
  end

  def self.xcodebuild(
    projectName:,
    scheme:,
    configuration:,
    destination:,
    sdk:,
    archivePath:,
    derivedDataPath:,
    otherOptions:
  )
    args = %W(-project "#{projectName}" -scheme "#{scheme}" -configuration "#{configuration}" -sdk "#{sdk}" -destination "#{destination}" -archivePath "#{archivePath}" -derivedDataPath "#{derivedDataPath}")
    args += otherOptions
    command = "xcodebuild archive #{args.join(" ")}"

    # puts command

    log = `#{command} 2>&1`

    exit_code = $?.exitstatus  # Process::Status
    is_succeed = (exit_code == 0)

    if !is_succeed
      begin
        if log.include?("** BUILD FAILED **")
          # use xcpretty to print build log
          # 64 represent command invalid. http://www.manpagez.com/man/3/sysexits/
          printer = XCPretty::Printer.new({ :formatter => XCPretty::Simple, :colorize => "auto" })
          log.each_line do |line|
            printer.pretty_print(line)
          end
        else
          raise "shouldn't be handle by xcpretty"
        end
      rescue
        puts log.red
      end
    end
    [is_succeed, log]
  end
end