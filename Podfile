source 'https://github.com/CocoaPods/Specs.git'
source 'https://github.com/MacPass/KeePassKit.git'
platform :ios, '12.0'
inhibit_all_warnings!
use_frameworks!

# versions probably should be set explicitly
target 'Passs' do
    pod 'SnapKit'
    pod 'RealmSwift'
    pod 'RxSwift'
    pod 'RxCocoa'
    pod 'RxRealm'
    pod 'KeePassKit', :git => 'https://github.com/fedorov-d/KeePassKit.git', :submodules => true
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
    end
  end
end