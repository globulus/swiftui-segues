Pod::Spec.new do |s|
  s.name             = 'SwiftUISegues'
  s.version          = '1.0.2'
  s.summary          = 'Easy-to-use segues in SwiftUI, allowing for presenting views using common UIKIt Segue types - push, modal and popover.'
  s.homepage         = 'https://github.com/globulus/swiftui-segues'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Gordan Glavaš' => 'gordan.glavas@gmail.com' }
  s.source           = { :git => 'https://github.com/globulus/swiftui-segues.git', :tag => s.version.to_s }
  s.ios.deployment_target = '13.0'
  s.swift_version = '4.0'
  s.source_files = 'Sources/SwiftUISegues/**/*'
end
