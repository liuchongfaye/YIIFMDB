Pod::Spec.new do |s|

  s.name         = "YIIFMDB"
  s.version      = "1.0.2"
  s.summary      = "基于FMDB的再一次封装，纯面向对象，直接操作Model，不需要写sqlite语句"
  s.homepage     = "https://github.com/liuchongfaye/YIIFMDB"
  s.license      = "MIT"
  s.author       = { "刘冲" => "liuchongfaye@163.com" }
  s.platform     = :ios
  s.ios.deployment_target = "7.0"
  s.source       = { :git => "https://github.com/liuchongfaye/YIIFMDB.git", :tag => "#{s.version}" }
  s.source_files  = "YIIFMDB/YIIFMDB/*.{h,m}"
  s.requires_arc = true
  s.framework  = "Foundation"
  s.dependency "FMDB"

end
