$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "validates-structure/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "validates-structure"
  s.version     = ValidatesStructure::VERSION
  s.authors     = ["Daniel Ström"]
  s.email       = ["D@nielstrom.se"]
  s.homepage    = "https://github.com/PugglePay/validates-structure"
  s.summary     = "Allows the creation of hash structures with ActiveModel::Validations."
  s.description = "Uses the power and familiarity of ActiveModel::Validations to validate hash structures. Designed for detecting and providing feedback on bad requests to your RESTful Web Service."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["LICENSE.txt", "Rakefile", "README.md"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 4.0.0"

  s.add_development_dependency "rspec"
  s.add_development_dependency "debugger"
end
