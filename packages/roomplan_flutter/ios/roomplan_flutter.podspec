#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
#
Pod::Spec.new do |s|
  s.name             = 'roomplan_flutter'
  s.version          = '0.2.0'
  s.summary          = 'A Flutter plugin to use Apple\'s RoomPlan API.'
  s.description      = <<-DESC
A Flutter plugin for iOS that provides access to Apple's RoomPlan API, allowing you to easily scan an interior room and receive a 3D model with detailed measurements.
                       DESC
  s.homepage         = 'https://github.com/Barba2k2/flutter_roomplan'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Barba Tech Company' => 'contato@barbatech.company' }
  s.source           = { :path => '.' }
  s.source_files = 'roomplan_flutter/Sources/roomplan_flutter/**/*.swift'
  s.dependency 'Flutter'
  s.platform = :ios, '16.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_versions = ['5.0']

  s.frameworks = ['RoomPlan']
  s.weak_frameworks = ['RoomPlan']
end 