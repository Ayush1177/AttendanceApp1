platform :ios, '17.0'

target 'AttendanceApp1' do
  use_frameworks!

  pod 'Firebase/Auth'
  pod 'Firebase/Firestore'

  post_install do |installer|
    installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
      end
    end
  end
end
