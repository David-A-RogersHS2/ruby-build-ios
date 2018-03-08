#!/usr/bin/ruby
#
# Authors: Don Bales, David A. Rogers
#
# Copyright (c) 2018 HS2 Solutions, Inc.
#


require './ruby_build_ios.rb'

def get_build_number_string()
  build_number = RubyBuildIos.latest_git_commit_count()
  build_number = build_number += 300000000
  return build_number.to_s
end


### QA methods

def release_to_qa()
  archive_file = build_qa()
  
  #upload the app to hockey
  api_token = "<hockey_api_token>"
  app_id = "<hockey_app_id>"
  hockey_note = RubyBuildIos.latest_git_commit_comment()
  
  # upload_to_hockey(app_id, api_token, note, file_to_upload)
  RubyBuildIos.upload_to_hockey(app_id, api_token, hockey_note, archive_file)
end


def build_qa()
  archive_path = './build/qa'
  archive_file = archive_path + '/TheApp.xcarchive'
  
  RubyBuildIos.clean(archive_path)
  
  # Copies the provision file to the appropriately named file in ~/Library/MobileDevice/Provisioning Profiles
  # where Xcode expects to find them.
  RubyBuildIos.install_provision_file('../../Profiles/THEAPP_QA_App.mobileprovision')
  RubyBuildIos.install_provision_file('../../Profiles/THEAPP_QA_WKApp.mobileprovision')
  RubyBuildIos.install_provision_file('../../Profiles/THEAPP_QA_WKExt.mobileprovision')
  RubyBuildIos.install_provision_file('../../Profiles/THEAPP_QA_SExt.mobileprovision')
  
  # build_workspace(workspace, scheme, configuration, build_number, archive_path)
  RubyBuildIos.build_workspace('TheApp.xcworkspace', 'TheApp', 'QA', get_build_number_string(), archive_file)

  return archive_file

end


### Productions methods
def release_to_prod()
  archive_path = build_prod()
  
  user = '<itunes user>'
  password = '<itunes pass>'
  
  RubyBuildIos.upload_to_itunes(user, password, "#{archive_path}/theapp.ipa")
end


def build_prod()
  archive_path = './build/prod'
  archive_file = archive_path + '/TheApp.xcarchive'


  RubyBuildIos.clean('./build')
  
  # Copies the provision file to the appropriately named file in ~/Library/MobileDevice/Provisioning Profiles
  # where Xcode expects to find them.
  RubyBuildIos.install_provision_file('../../Profiles/THEAPP_Prod_App.mobileprovision')
  RubyBuildIos.install_provision_file('../../Profiles/THEAPP_Prod_WKApp.mobileprovision')
  RubyBuildIos.install_provision_file('../../Profiles/THEAPP_Prod_WKExt.mobileprovision')
  RubyBuildIos.install_provision_file('../../Profiles/THEAPP_Prod_SExt.mobileprovision')
  
  # build_workspace(workspace, scheme, configuration, build_number, archive_path)
  RubyBuildIos.build_workspace('TheApp.xcworkspace', 'TheApp', 'Release', get_build_number_string(), archive_file)

  
  plist_file = './build/build.plist'
  provision_keys = {
    "com.theapp.iphoneapp" => "THEAPP Prod App",
    "com.theapp.iphoneapp.watchkitapp" => "THEAPP Prod WKApp",
    "com.theapp.iphoneapp.watchkitapp.extension" => "THEAPP Prod WKExt",
    "com.theapp.iphoneapp.notificationserviceext" => "THEAPP Prod SExt" }
    
  RubyBuildIos.create_export_plist(plist_file, provision_keys)
  
  RubyBuildIos.export_to_ipa(archive_file, plist_file, archive_path)

  return archive_path
  
end


if ARGV[0] == 'release_to_qa'
  release_to_qa()
elsif ARGV[0] == 'build_qa'
  build_qa()
elsif ARGV[0] == 'release_to_prod'
  release_to_prod()
elsif ARGV[0] == 'build_prod'
  build_prod()
else
  print "Usage: example.rb [release_to_qa | release_to_prod | build_qa | build_prod]\n"
end


