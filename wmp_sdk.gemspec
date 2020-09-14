require_relative 'lib/wmp_sdk/version'

Gem::Specification.new do |spec|
  spec.name    = 'wmp_sdk'
  spec.version = WmpSdk::VERSION
  spec.authors = ['JiangYongKang']
  spec.email   = ['vincent4502237@gmail.com']

  spec.summary               = 'wechat miniprogram sdk for ruby'
  spec.description           = 'a ruby program to facilitate accessing wechat miniprogram'
  spec.homepage              = 'https://github.com/JiangYongKang/wmp_sdk'
  spec.license               = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata['homepage_uri']    = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/JiangYongKang/wmp_sdk'
  spec.metadata['changelog_uri']   = 'https://github.com/JiangYongKang/wmp_sdk'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
end
