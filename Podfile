source 'https://github.com/CocoaPods/Specs.git'
source 'https://github.com/MacPass/KeePassKit.git'
platform :ios, '13.0'
inhibit_all_warnings!
use_frameworks!

# versions probably should be set explicitly
def common
    pod 'KeePassKit', :git => 'https://github.com/fedorov-d/KeePassKit.git', :submodules => true
end

target 'Keep' do
    pod 'SnapKit'
    common
end

target 'CredentialProvider' do
  pod 'SnapKit'
  common
end

target 'PasssTests' do
  common
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
    end
  end
end
