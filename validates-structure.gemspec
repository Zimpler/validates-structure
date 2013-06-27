$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "validates-structure/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "validates-structure"
  s.version     = ValidatesStructure::VERSION
  s.authors     = ["Daniel Ström"]
  s.email       = ["D@nielstrom.se"]
  s.homepage    = "pugglepay.com"
  s.summary     = "TODO: Summary of ValidatesStructure."
  s.description = "TODO: Description of ValidatesStructure."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 3.2.13"

  s.add_development_dependency "sqlite3"
end
