Pod::Spec.new do |spec|
  spec.name         = "NetfilmPlayerKit"
  spec.version      = "1.0.0"
  spec.summary      = "مكتبة لتشغيل الفيديو في iOS"
  spec.description  = "NetfilmPlayer هي مكتبة سهلة الاستخدام لتشغيل الفيديوهات باستخدام AVPlayer مع دعم SnapKit و NVActivityIndicatorView."
  spec.homepage     = "https://github.com/اسم_المستخدم/NetfilmPlayer"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author       = { "Mjeed Alanazi (pzx)" => "tt666tta@gmail.com" }
  spec.platform     = :ios, "13.0"
  spec.source       = { :git => "https://github.com/pzx3/NetfilmPlayerKit.git", :tag => spec.version.to_s }
  spec.swift_version = "5.7"

  # مسار الكود الخاص بالمكتبة
  spec.source_files = "Source/*.swift"
  
  # إذا كنت تستخدم موارد مثل الصور أو الملفات
  spec.resource_bundles = {
    "NetfilmPlayer" => ["Source/*.xcassets"]
  }

  # التبعيات التي تعتمد عليها المكتبة
  spec.dependency "SnapKit"
  spec.dependency "NVActivityIndicatorView"
end
