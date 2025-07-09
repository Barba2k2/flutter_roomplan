#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
#
Pod::Spec.new do |s|
  s.name             = 'roomplan_flutter'
  s.version          = '0.0.1'
  s.summary          = 'A Flutter plugin to use Apple\'s RoomPlan API.'
  s.description      = <<-DESC
A new Flutter plugin to use RoomPlan API for scanning rooms.
                       DESC
  s.homepage         = 'https://github.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'PaintPro' => 'suporte@paintpro.com.br' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '16.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  s.frameworks = ['RoomPlan']
  s.weak_frameworks = ['RoomPlan']
end 