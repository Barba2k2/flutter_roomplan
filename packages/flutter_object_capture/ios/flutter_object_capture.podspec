#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_object_capture'
  s.version          = '0.0.1'
  s.summary          = 'A Flutter plugin to use Apple\'s RealityKit Object Capture (PhotogrammetrySession).'
  s.description      = <<-DESC
A Flutter plugin for iOS that wraps Apple's Object Capture pipeline:
guided photo capture (ObjectCaptureSession) and on-device photogrammetry
(PhotogrammetrySession) producing textured USDZ models.
                       DESC
  s.homepage         = 'https://github.com/Barba2k2/flutter_roomplan/tree/master/packages/flutter_object_capture'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'PaintPro' => 'suporte@paintpro.com.br' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '17.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  s.frameworks = ['RealityKit']
  s.weak_frameworks = ['RealityKit']
end
