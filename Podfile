# Uncomment the next line to define a global platform for your project
  platform :ios, '9.1'

target 'RAC_Tester941' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for RAC_Tester941
	pod 'ReactiveCocoa', '< 3'

end

post_install do |installer|
	installer.pods_project.targets.each do |target|
		target.build_configurations.each do |config|
			config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '9.1'
			
# this has no effect?
# instead we have changed this build setting directly in Pods project
# for both 'ReactiveCocoa-framework' and 'ReactiveCocoa-library'
#			if target.name == 'ReactiveCocoa'
#				config.build_settings['CLANG_WARN_STRICT_PROTOTYPES'] = 'NO'
#			end
		end
	end
end
