Pod::Spec.new do |spec|
  spec.name                     = 'Leap-Model-Downloader'
  spec.version                  = '0.9.4'
  spec.summary                  = 'Leap Model Downloader for iOS'
  spec.homepage                 = 'https://github.com/Liquid4All/leap-ios'
  spec.license                  = { :type => 'Proprietary', :text => 'Copyright 2025 Liquid AI.' }
  spec.author                   = { 'Liquid AI' => 'support@liquid.ai' }
  spec.source                   = {
    :http => 'https://github.com/Liquid4All/leap-ios/releases/download/v0.9.4/LeapModelDownloader.xcframework.zip'
  }
  spec.ios.deployment_target    = '15.0'
  spec.swift_version            = '5.9'
  spec.vendored_frameworks      = 'LeapModelDownloader.xcframework'
  spec.frameworks               = 'Foundation'
  spec.requires_arc             = true
  spec.source_files             = []
end
