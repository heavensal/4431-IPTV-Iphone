require 'xcodeproj'
require 'fileutils'
root = File.expand_path('..', __dir__)
Dir.chdir(root)
project = Xcodeproj::Project.new('4431-IPTV-Iphone.xcodeproj')
app = project.new_target(:application, 'IPTVPhone', :ios, '17.0')
widget = project.new_target(:app_extension, 'IPTVIsland', :ios, '17.0')
tests = project.new_target(:unit_test_bundle, 'IPTVTests', :ios, '17.0')
sources = project.main_group.new_group('Sources', 'Sources')
Dir['Sources/*.swift'].sort.each { |path| app.source_build_phase.add_file_reference(sources.new_file(File.basename(path))) }
shared = project.main_group.new_group('Shared', 'Shared')
attributes = shared.new_file('PlaybackActivity.swift')
[app,widget].each { |target| target.source_build_phase.add_file_reference(attributes) }
island = project.main_group.new_group('Island', 'Island')
widget.source_build_phase.add_file_reference(island.new_file('Island.swift'))
test_group = project.main_group.new_group('Tests', 'Tests')
Dir['Tests/*.swift'].sort.each { |path| tests.source_build_phase.add_file_reference(test_group.new_file(File.basename(path))) }
framework = project.frameworks_group.new_file('Vendor/MobileVLCKit.xcframework')
app.frameworks_build_phase.add_file_reference(framework)
framework_embed = app.new_copy_files_build_phase('Embed Frameworks')
framework_embed.dst_subfolder_spec = '10'
framework_embed.add_file_reference(framework).settings = {'ATTRIBUTES'=>['CodeSignOnCopy','RemoveHeadersOnCopy']}
app.resources_build_phase.add_file_reference(project.main_group.new_file('Assets.xcassets'))
app.add_dependency(widget)
embed = app.new_copy_files_build_phase('Embed App Extensions')
embed.dst_subfolder_spec = '13'
embed.add_file_reference(widget.product_reference).settings = {'ATTRIBUTES'=>['RemoveHeadersOnCopy']}
tests.add_dependency(app)
[app,widget,tests].each do |target|
  target.build_configurations.each do |config|
    config.build_settings.merge!({
      'SWIFT_VERSION'=>'5.0', 'IPHONEOS_DEPLOYMENT_TARGET'=>'17.0',
      'TARGETED_DEVICE_FAMILY'=>'1', 'CODE_SIGN_STYLE'=>'Automatic',
      'MARKETING_VERSION'=>'0.0.1', 'CURRENT_PROJECT_VERSION'=>'1',
      'SUPPORTED_PLATFORMS'=>'iphoneos iphonesimulator',
      'SUPPORTS_MACCATALYST'=>'NO',
      'LD_RUNPATH_SEARCH_PATHS'=>['$(inherited)','@executable_path/Frameworks'],
      'PRODUCT_BUNDLE_IDENTIFIER'=> "com.heavensal.iptvphone#{target == app ? '' : target == widget ? '.island' : '.tests'}"
    })
  end
end
app.build_configurations.each do |config|
  config.build_settings['INFOPLIST_FILE'] = 'Info.plist'
  config.build_settings['ASSETCATALOG_COMPILER_APPICON_NAME']='AppIcon'
  config.build_settings['OTHER_LDFLAGS'] = ['$(inherited)','-ObjC','-lc++','-liconv','-lz','-lbz2']
end
%w[AVFoundation AudioToolbox CoreMedia CoreVideo VideoToolbox OpenGLES QuartzCore Security].each do |name|
  app.frameworks_build_phase.add_file_reference(project.frameworks_group.new_file("System/Library/Frameworks/#{name}.framework",:sdk_root))
end
widget.build_configurations.each do |config|
  config.build_settings['INFOPLIST_FILE']='Island/Info.plist'
  config.build_settings['APPLICATION_EXTENSION_API_ONLY']='YES'
  config.build_settings['SKIP_INSTALL']='YES'
end
tests.build_configurations.each do |config|
  config.build_settings['GENERATE_INFOPLIST_FILE']='YES'
  config.build_settings['TEST_HOST']='$(BUILT_PRODUCTS_DIR)/IPTVPhone.app/IPTVPhone'
  config.build_settings['BUNDLE_LOADER']='$(TEST_HOST)'
end
project.save
scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(app)
scheme.set_launch_target(app)
scheme.add_test_target(tests)
scheme.save_as(project.path,'IPTVPhone',true)
