Pod::Spec.new do |spec|
  spec.name                     = 'Inference-Engine-Executorch-Backend'
  spec.version                  = '0.9.4'
  spec.summary                  = 'Leap inference engine ExecuTorch backend'
  spec.homepage                 = 'https://github.com/Liquid4All/leap-ios'
  spec.license                  = { :type => 'Proprietary', :text => 'Copyright 2025 Liquid AI.' }
  spec.author                   = { 'Liquid AI' => 'support@liquid.ai' }
  spec.source                   = {
    :http => 'https://github.com/Liquid4All/leap-ios/releases/download/v0.9.4/inference_engine_executorch_backend.xcframework.zip'
  }
  spec.ios.deployment_target    = '15.0'
  spec.vendored_frameworks      = 'inference_engine_executorch_backend.xcframework'
  spec.requires_arc             = true
  spec.source_files             = []
end
