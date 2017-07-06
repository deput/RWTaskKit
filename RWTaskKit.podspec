Pod::Spec.new do |s|
  s.name             = "RWTaskKit"
  s.version          = "0.1.0"
  s.license          = { :type => 'MIT' }
  s.summary          = "A Kit to dispatch tasks neatly"
  s.description      = "A Kit to dispatch tasks neatly"
  s.homepage         = "https://github.com/deput/RWTaskKit"

  s.author           = { "deput" => "canopus4u@outlook.com" }
  s.source           = { :git => "https://github.com/deput/RWTaskKit.git", :branch => "master"}

  s.platform         = :ios, '7.0'
  s.ios.deployment_target = '7.0'
  s.requires_arc     = true

  s.frameworks = 'Foundation'
  s.source_files  = "RWTaskKit/{Core,Vendor}/**/*.{h,m}"

end
