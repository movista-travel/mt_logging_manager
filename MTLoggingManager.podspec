#
# Be sure to run `pod lib lint MTLoggingManager.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'MTLoggingManager'
  s.version          = '0.1.0'
  s.summary          = 'A short description of MTLoggingManager.'
  s.static_framework = true
# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.homepage         = 'https://github.com/movista-travel/mt_logging_manager'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'juicyfru1t' => 'akhodko@movista.ru' }
  s.source           = { :git => 'https://github.com/movista-travel/mt_logging_manager.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

  s.source_files = 'MTLoggingManager/Classes/**/*'
  s.swift_versions = ['5.0']
  
  # s.resource_bundles = {
  #   'MTLoggingManager' => ['MTLoggingManager/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  #s.frameworks = 'Crashlytics', 'Fabric'
  # s.dependency 'AFNetworking', '~> 2.3'
  s.dependency 'SwiftyBeaver'
  s.dependency 'Fabric'
  s.dependency 'Crashlytics'
  s.pod_target_xcconfig = {
    'FRAMEWORK_SEARCH_PATHS' => '$(inherited) $(PODS_ROOT)/Crashlytics/iOS'
  }
end
