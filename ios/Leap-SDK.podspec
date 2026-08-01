Pod::Spec.new do |spec|
  spec.name                     = 'Leap-SDK'
  spec.version                  = '0.9.4'
  spec.summary                  = 'LeapSDK for iOS'
  spec.homepage                 = 'https://github.com/Liquid4All/leap-ios'
  spec.license                  = { :type => 'Proprietary', :text => 'Copyright 2025 Liquid AI.' }
  spec.author                   = { 'Liquid AI' => 'support@liquid.ai' }
  spec.source                   = {
    :http => 'https://github.com/Liquid4All/leap-ios/releases/download/v0.9.4/LeapSDK.xcframework.zip'
  }
  spec.ios.deployment_target    = '15.0'
  spec.swift_version            = '5.9'
  spec.vendored_frameworks      = 'LeapSDK.xcframework'
  spec.frameworks               = 'Foundation'
  spec.requires_arc             = true
  spec.source_files             = []
  # LeapSDK は inference_engine 系バイナリに @rpath 依存（Package.swift 参照）
  spec.dependency 'Inference-Engine', '0.9.4'
  spec.dependency 'Inference-Engine-Executorch-Backend', '0.9.4'
  spec.dependency 'Inference-Engine-LlamaCpp-Backend', '0.9.4'
  spec.dependency 'Leap-Model-Downloader', '0.9.4'
  spec.prepare_command = <<-CMD
    if [ ! -d "LeapSDK.xcframework" ]; then
      curl -fsSL -o LeapSDK.xcframework.zip \
        "https://github.com/Liquid4All/leap-ios/releases/download/v0.9.4/LeapSDK.xcframework.zip"
      unzip -qo LeapSDK.xcframework.zip
      rm -f LeapSDK.xcframework.zip
    fi
  CMD
end
