# ruby-build-ios.rb
#
# Authors Don Bales, David A. Rogers
#
# Copyright (c) 2018 HS2 Solutions, Inc.
#

module RubyBuildIos
  require 'open3'

  PROJECT_BUILD_NUMBER = 'PROJECT_BUILD_NUMBER';
  
  # https://ruby-doc.org/stdlib-2.0.0/libdoc/open3/rdoc/Open3.html#method-c-capture3
  # https://ruby-doc.org/core-2.2.0/Process/Status.html
  # http://ruby-doc.org/core-2.0.0/IO.html#method-i-puts

  def self.latest_git_commit_count(revision = 'HEAD')
    command = "git rev-list --count #{revision}"
    print "#{command}\n"
    # status is a Process::Status 
    stdout_str, stderr_str, status = Open3.capture3(command)
    if status.success?
      print "#{stdout_str}\n"
    else
      raise stderr_str;
    end
    result = stdout_str.chomp.chomp  
    result.to_i
  end

  def self.latest_git_commit_comment(revision = '--all') 
    command = "git log -1 --oneline #{revision}"
    print "#{command}\n"
    # status is a Process::Status 
    stdout_str, stderr_str, status = Open3.capture3(command)  
    if status.success?
      print "#{stdout_str}\n"
    else
      raise stderr_str;
    end
    result = stdout_str.chomp.chomp  
  end
    
  def self.tag_latest_git_commit(tag, message = 'Sorry, no tag message provided.')
    command = "git tag -a #{tag} -m \"#{message}\""
    print "#{command}\n"
    # status is a Process::Status 
    # -a is annotate
    # -m is message
    # ex: git tag -a v1.4 -m "my version 1.4"
    stdout_str, stderr_str, status = Open3.capture3(command)
    if status.success?
      print "#{stdout_str}\n"
    else
      raise stderr_str;
    end
    result = stdout_str
    command = "git push origin #{tag}"
    print "#{command}\n"
    # ex: git push origin v1.4
    stdout_str, stderr_str, status = Open3.capture3(command)
    if status.success?
      print "#{stdout_str}\n"
    else
      raise stderr_str;
    end

    result = "#{result}\n#{stdout_str}" 
  end
  
  def self.project_build_number(file_name = PROJECT_BUILD_NUMBER)
    print "Reading from #{file_name} to get the last project build number\n"
    file = File.open(file_name, 'r')
    build_str = file.gets()
    file.close()
    
    build_int = build_str.chomp.to_i
    
    build_int += 1
      
    build_str = build_int.to_s
    
    print "Writing into #{file_name} to set the next project build number\n"
    file = File.open(file_name, 'w+', 0666)
    file.puts(build_str)
    file.close()
    
    build_str
  end  
  
  def self.get_uuid_from_file(file_name)
    command = "/usr/libexec/PlistBuddy -c \"Print UUID\" /dev/stdin <<< $(security cms -D -i #{file_name} 2> /dev/null)"
    print "#{command}\n"
    # status is a Process::Status 
    stdout_str, stderr_str, status = Open3.capture3(command)
    if status.success?
      stdout_str = stdout_str.chomp
      print "#{stdout_str}\n"
    else
      raise stderr_str;
    end
    result = stdout_str    
  end
  
  def self.copy_provision_file(file_name, uuid)
    command = "cp #{file_name} ~/Library/MobileDevice/Provisioning\\ Profiles/#{uuid}.mobileprovision"
    print "#{command}\n"
    # status is a Process::Status 
    stdout_str, stderr_str, status = Open3.capture3(command)
    if status.success?
      print "#{stdout_str}\n"
    else
      raise stderr_str;
    end
    result = stdout_str    
  end

  def self.install_provision_file(file_name)
    uuid = get_uuid_from_file(file_name)
    copy_provision_file(file_name, uuid)
  end
  
  def self.install_provision_files(file_names_str)
    file_names = file_name_str.gsub("\n",'').strip().split(',')
    file_names.each do |file_name|
      uuid = get_uuid_from_file(file_name)
      copy_provision_file(file_name, uuid)
    end
  end
  
  def self.upload_to_hockey(app_id, api_token, note, file_to_upload)
    command = "puck -app_id=#{app_id} -api_token=#{api_token} -submit=auto -download=true -notify=true -notes=\"#{note}\" #{file_to_upload}"
    print "#{command}\n"
    # status is a Process::Status 
    stdout_str, stderr_str, status = Open3.capture3(command)
    if status.success?
      print "#{stdout_str}\n"
    else
      raise stderr_str;
    end
    result = stdout_str    
  end
  
  def self.clean(path)
    if path.chomp == '/'
      raise "Are you out of your mind?"
    end
    command = "rm -fr #{path}/*"
    print "#{command}\n"
    # status is a Process::Status 
    stdout_str, stderr_str, status = Open3.capture3(command)
    if status.success?
      print "#{stdout_str}\n"
    else
      raise stderr_str;
    end
    result = stdout_str    
  end
  
  # TODO allow flexibility in USER DEFINED build variables
  def self.build_project(project, scheme, configuration, build_number, archive_path)
    command = "xcodebuild -project #{project} -scheme #{scheme} -configuration #{configuration} -destination 'generic/platform=iOS' PROJECT_BUILD_NUMBER=#{build_number} -archivePath #{archive_path} archive"
    print "#{command}\n"
    # status is a Process::Status 
    result = 'OK'
    status = nil
    stderr_str = ''
    Open3.popen3(command) do |stdin, stdout, stderr, wait|

      t1 = Thread.new do
        while line = stdout.gets
          puts line
        end
      end
      
      t2 = Thread.new do
        while line = stderr.gets
          stderr_str << line
        end
      end
      
      status = wait.value
      t2.value
      t1.value
    end
      
    if status.success?
      print "#{result}\n"
    else
      raise stderr_str;
    end
    result    
  end

  # TODO allow flexibility in USER DEFINED build variables  
  def self.build_workspace(workspace, scheme, configuration, build_number, archive_path)
    command = "xcodebuild -workspace #{workspace} -scheme #{scheme} -configuration #{configuration} -destination 'generic/platform=iOS' PROJECT_BUILD_NUMBER=#{build_number} -archivePath #{archive_path} archive"
    print "#{command}\n"
    # status is a Process::Status 
    result = 'OK'
    status = nil
    stderr_str = ''
    Open3.popen3(command) do |stdin, stdout, stderr, wait|

      t1 = Thread.new do
        while line = stdout.gets
          puts line
        end
      end
      
      t2 = Thread.new do
        while line = stderr.gets
          stderr_str << line
        end
      end
      
      status = wait.value
      t2.value
      t1.value
    end
      
    if status.success?
      print "#{result}\n"
    else
      raise stderr_str;
    end
    result    
  end

  def self.create_export_plist(file_name, key_string_pairs)
    if !key_string_pairs.is_a? Hash
      raise "create_export_plist() key_string_pairs must be a Hash\n"
    end
    
    xml_prelude = <<EO1
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>provisioningProfiles</key>
    <dict>
EO1
    xml_postlude = <<EO2
      </dict>
    <key>method</key>
    <string>app-store</string>
</dict>
</plist>
EO2
    xml_key_string_pairs = ''
    key_string_pairs.each_pair do |key, string|
      xml_key_string_pairs << "        <key>#{key}</key>\n"
      xml_key_string_pairs << "        <string>#{string}</string>\n"
    end

    print "Writing into #{file_name}\n"
    file = File.open(file_name, 'w+', 0666)
    file.puts("#{xml_prelude}#{xml_key_string_pairs}#{xml_postlude}")
    file.close()

    return true
  end  

  def self.create_enterprise_plist(file_name)
    
    xml_enterprise = <<EO1
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>enterprise</string>
</dict>
</plist>
EO1

    print "Writing into #{file_name}\n"
    file = File.open(file_name, 'w+', 0666)
    file.puts("#{xml_enterprise}")
    file.close()

    return true
  end  

  
  def self.xcode_path()
    command = "dirname \"$(xcode-select -p)\""
    print "#{command}\n"
    # status is a Process::Status 
    stdout_str, stderr_str, status = Open3.capture3(command)
    if status.success?
      print "#{stdout_str}\n"
    else
      raise stderr_str;
    end
    result = stdout_str.chomp.chomp    
  end
  
  def self.export_to_ipa(archive, plist, ipa_path)
    command = "xcodebuild -exportArchive -exportOptionsPlist #{plist} -archivePath #{archive} -exportPath #{ipa_path}"
    print "#{command}\n"
    # status is a Process::Status 
    stdout_str, stderr_str, status = Open3.capture3(command)
    if status.success?
      print "#{stdout_str}\n"
    else
      raise stderr_str;
    end
    result = stdout_str        
  end
  
  # May want to stream stderr to console too, because altool uses stderr instead of stdout
  def self.validate_with_itunes(user, password, ipa)
    # get altools path
    xcode_path = self.xcode_path
    altool = "#{xcode_path}/Applications/Application\\ Loader.app/Contents/Frameworks/ITunesSoftwareService.framework/Versions/A/Support/altool"
    command = "#{altool} --validate-app --type ios -u \"#{user}\" -p \"#{password}\"  -f #{ipa}"
    print "#{command}\n"
    result = 'OK'
    status = nil
    stderr_str = ''
    Open3.popen3(command) do |stdin, stdout, stderr, wait|

      t1 = Thread.new do
        while line = stdout.gets
          puts line
        end
      end
      
      t2 = Thread.new do
        while line = stderr.gets
          puts line
          stderr_str << line
        end
      end
      
      status = wait.value
      t2.value
      t1.value
    end
      
    if status.success?
      print "#{result}\n"
    else
      raise stderr_str;
    end
    result    
  end

  # May want to stream stderr to console too, because altool uses stderr instead of stdout
  def self.upload_to_itunes(user, password, ipa)
    # get altools path
    xcode_path = self.xcode_path
    altool = "#{xcode_path}/Applications/Application\\ Loader.app/Contents/Frameworks/ITunesSoftwareService.framework/Versions/A/Support/altool"
    command = "#{altool} --upload-app --type ios -u \"#{user}\" -p \"#{password}\"  -f #{ipa}"
    print "#{command}\n"
    result = 'OK'
    status = nil
    stderr_str = ''
    Open3.popen3(command) do |stdin, stdout, stderr, wait|

      t1 = Thread.new do
        while line = stdout.gets
          puts line
        end
      end
      
      t2 = Thread.new do
        while line = stderr.gets
          puts line
          stderr_str << line
        end
      end
      
      status = wait.value
      t2.value
      t1.value
    end
      
    if status.success?
      print "#{result}\n"
    else
      raise stderr_str;
    end
    result    
  end
  
end
