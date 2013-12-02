Validates Structure
===================

Validates Structure allows you to easily validate hash-structures using ActiveModel::Validations.


Dependencies
------------
The gem works for ActiveModel 4 and above.


Installation
------------
Simply add the gem to your gemfile:

```ruby
gem 'validates-structure'
```

and make sure your activemodel version is at least 4.0.0:

```ruby
gem 'activemodel', '>=4.0.0'
```

Remember to

```ruby
require 'validates-structure'
```

at the top of the file when defining a new structure.

Canonical Usage Example
------------

```ruby
require 'validates-structure'

class MyCanonicalValidator < ValidatesStructure::Validator
  key 'foo', Hash do
    key 'bar', Array do
      value Integer, allow_nil: true
    end
    key 'baz', String, format: /\A[0-f]\z/
  end
end

validator = MyCanonicalValidator.new({foo: {bar: [1, 2, nil, 'invalid']}})
validator.valid?
# => false
puts validator.errors.full_messages
# => /foo/bar[3] has class "String" but should be a "Integer"
# => /foo/baz is invalid
# => /foo/baz must not be nil
```

Quick facts about Validates Structure
-------------------------------------
* Validates Structure uses ActiveModel::Validations to validate your hash.
* Validates Structure automatically validates the type of each declared entry and will also give an error when undeclared keys are present.
* You can validate that a value are true or false by using the `Boolean` class (even though there are no Boolean class i Ruby).
* You can make compound hashes by setting a subclass to ValidatesStructure::Validator as the class in a key or value declaration.
* It doesn't matter if your structure uses symbols or strings as hash keys.
* Just like when validating attributes in a model, you can use your own custom validations.

Examples
--------

### Minimal example

```ruby
class MySimpleValidator < ValidatesStructure::Validator
  key 'apa', Integer
end

MySimpleValidator.new(apa: 3).valid?
# => true
```

### Boolean example

```ruby
class MyBooleanValidator < ValidatesStructure::Validator
  key 'apa', Boolean
end

MyBooleanValidator.new(apa: true).valid?
# => true
```

### Nested example

```ruby
class MyNestedValidator < ValidatesStructure::Validator
  key 'apa', Hash do
    key 'bepa', String, presence: true
  end
end

validator = MyNestedValidator.new(apa: { bepa: "" })
validator.valid?
# => false
puts validator.errors.full_messages
# => /apa/bepa can't be blank
```

### Array example

```ruby
class MyArrayValidator < ValidatesStructure::Validator
  key 'apa', Hash do
    key 'bepa', Array do
      value Integer
    end
  end
end

validator = MyArrayValidator.new(apa: { bepa: [1, 2, "3"] })
validator.valid?
# => true
puts validator.errors.full_messages
# => /apa/bepa[2] has class "String" but should be a "Integer"
```

### Compound example

```ruby
class MyInnerValidator < ValidatesStructure::Validator
  key 'bepa', Integer
end

class MyOuterValidator < ValidatesStructure::Validator
  key 'apa', MyInnerValidator
end

MyOuterValidator.new(apa: { bepa: 3 }).valid?
# => true
```

### Custom validator example

```ruby
class OddValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    record.errors.add attribute, "can't be even." if value.even?
  end
end

class MyCustomValidator < ValidatesStructure::Validator
  key 'apa', Integer, odd: true
end

MyCustomValidator.new(apa: 3).valid?
# => true
```


Documentation
-------------
This documentation is about the modules, classes, methods and options of ValidatesStructure. For documentation on ActiveModel::Validations see [the ActiveModel documentation.](http://apidock.com/rails/ActiveModel/Validations/ClassMethods/validates)

### ValidatesStructure::Validator

#### self.key(index, klass, validations={}, &block)
Sets up a requirement on the form ```'index' => klass``` that are validated with _validations_ and containing children on the form specified in _&block_.

**Parameters**

_index_ - The string or symbol by which to retrieve the value

_klass_ - The required class of the value. If klass is a subclass of ValidatesStructure::Validator then the value is validated as specified in its definition.

_validations_ - A hash with [ActiveModel:Validations](http://api.rubyonrails.org/classes/ActiveModel/Validations/HelperMethods.html) on the same format as for the [validates](http://apidock.com/rails/ActiveModel/Validations/ClassMethods/validates) method.

_&block_ - A block of nested _key_ and/or _value_ declarations. Only applicable if klass is an Array or Hashe.


#### self.value(klass, validations={},&block)
Sets up a requirement like self.key but without an index. Useful for structures that are accessed by a numeric index such as Arrays.

**Parameters**

_klass_ - The required class of the value. If klass is a subclass of ValidatesStructure::Validator then the value is validated as specified in its definition.

_validations_ - A hash with [ActiveModel:Validations](http://api.rubyonrails.org/classes/ActiveModel/Validations/HelperMethods.html) on the same format as for the [validates](http://apidock.com/rails/ActiveModel/Validations/ClassMethods/validates) method.

_&block_ - A block of nested _key_ and/or _value_ declarations. Only applicable if klass is an Array or Hashe.


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