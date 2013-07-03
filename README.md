Validates Structure
===================

Validates Structure allows you to easily validate hash-structures using ActiveModel::Validations.


Dependencies
------------
The gem works for Rails 4 and above.


Installation
------------
Simply add the gem to your gemfile:

```ruby
gem 'validates-structure'
```

and make sure your rails version is at least 4.0.0:

```ruby
gem 'rails', '>=4.0.0'
```

Usage Example
------------

```ruby
class MyStructuredHash < ValidatesStructure::StructuredHash
  key 'apa', Hash, presence: true do
    key 'bepa', Array, presence: true do
      value Integer, presence: true
    end
  end
end

my_hash = MyStructuredHash.new({apa: {bepa: [2, 3, 'invalid']}})
my_hash.valid?
# => false
my_hash.errors.each { |attr, error| puts "#{attr}: #{error}"}
# => //apa/bepa[2]: has type "String" but should be a "Integer".

```

Quick facts about Validates Structure
-------------------------------------
* A String given to the ValidatesStructure::StructuredHash::new method will be automatically evaluated as json.
* You can make compound hashes by setting a sublass to ValidatesStructure::StructuredHash as the type in a key or value declaration.
* You can use a subset of XPath to access attributes in such a way that `my_hash[:apa][:bepa][3]` and `my_hash['//apa/bepa[3]']` are equivalent.
* It doesn't matter if you access values using strings or symbols ```my_hash[:apa] ``` and ```my_hash['apa'] ``` are equivalent.
* Just like when validating fields in a model, you can use your own custom validations.


Documentation
-------------


Examples
--------


Some History
------------
This project was initiated by the good fellows at [PugglePay](https://github.com/PugglePay) who felt there should be some easy, familiar way of validating their incoming json requests and wanted to share their solution with the world.


Contributing
------------
1. Fork the project
2. Create a feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push branch to remote (git push origin my-new-feature)
5. Make a Pull Request