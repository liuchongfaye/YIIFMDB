Pod::Spec.new do |s|

  s.name         = "YIIFMDB"
  s.version      = "1.0.0"
  s.summary      = "基于FMDB的再一次封装，纯面向对象，不需要写sqlite语句"
  s.homepage     = "https://github.com/liuchongfaye/YIIFMDB"
  s.license      = "MIT"
  s.author       = { "刘冲" => "liuchongfaye@163.com" }
  s.platform     = :ios
  s.source       = { :git => "https://github.com/liuchongfaye/YIIFMDB.git", :tag => "#{s.version}" }
  s.source_files  = "YIIFMDB/YIIFMDB/*.{h,m}"
  s.requires_arc = true
  s.dependency "FMDB"

end
