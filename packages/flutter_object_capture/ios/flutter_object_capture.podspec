#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_object_capture'
  s.version          = '0.0.1'
  s.summary          = 'A Flutter plugin to use Apple\'s RealityKit Object Capture.'
  s.description      = <<-DESC
A Flutter plugin for iOS that wraps Apple's RealityKit Object Capture (PhotogrammetrySession) to turn a folder of photos into a textured 3D model.
                       DESC
  s.homepage         = 'https://github.com/Barba2k2/flutter_roomplan'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Barba Tech Company' => 'contato@barbatech.company' }
  s.source           = { :path => '.' }
  s.source_files = 'flutter_object_capture/Sources/flutter_object_capture/**/*.swift'
  s.dependency 'Flutter'
  s.platform = :ios, '17.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_versions = ['5.0']

  s.weak_frameworks = ['RealityKit']
end
