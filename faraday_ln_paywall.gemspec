# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "faraday_ln_paywall/version"

Gem::Specification.new do |spec|
  spec.name          = "faraday_ln_paywall"
  spec.version       = FaradayLnPaywall::VERSION
  spec.authors       = ["bumi"]
  spec.email         = ["hello@michaelbumann.com"]

  spec.summary       = %q{Faraday middleware to send lightning payments for requests}
  spec.description   = %q{Sends payments}
  spec.homepage      = "https://github.com/bumi/faraday_ln_paywall"
  spec.license       = "MIT"


  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"

  spec.add_dependency "lightning-invoice", "~> 0.1.2"
  spec.add_dependency "faraday", "> 0.8"
  spec.add_dependency "grpc", ">= 1.16.0"
end
