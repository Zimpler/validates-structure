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

Remember to

```ruby
require 'validates-structure'
```

at the top of the file when defining a new structure.

Canonical Usage Example
------------

```ruby
require 'validates-structure'

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
my_hash.errors.full_messages.join('\n')
# => //apa/bepa[2]: has class "String" but should be a "Integer".

```

Quick facts about Validates Structure
-------------------------------------
* Validates Structure uses ActiveModel::Validations to validate your hash.
* Validates Structure automatically validates the class of each declared entry and will give an error when undeclared keys are present.
* You can validate that a value are true or false by using the `Boolean` class (even though there are no Boolean class i Ruby).
* A String given to the ValidatesStructure::StructuredHash::new method will be automatically evaluated as json.
* You can make compound hashes by setting a subclass to ValidatesStructure::StructuredHash as the class in a key or value declaration.
* You can use a subset of XPath to access attributes in such a way that `my_hash[:apa][:bepa][3]` and `my_hash['//apa/bepa[3]']` are equivalent.
* It doesn't matter if you access values using strings or symbols; ```my_hash[:apa] ``` and ```my_hash['apa'] ``` are equivalent.
* Just like when validating fields in a model, you can use your own custom validations.

Examples
--------

### Minimal example

```ruby
class MySimpleHash < ValidatesStructure::StructuredHash
  key 'apa', Integer, presence: true
end

MySimpleHash.new(apa: 3).valid?
# => true
```

### Boolean example

```ruby
class MySimpleHash < ValidatesStructure::StructuredHash
  key 'apa', Boolean
end

MySimpleHash.new(apa: true).valid?
# => true
```

### Nested example

```ruby
class MyStructuredHash < ValidatesStructure::StructuredHash
  key 'apa', Hash, presence: true do
    key 'bepa', Integer, presence: true, format: { with: /3/i}
  end
end

MyStructuredHash.new(apa: { bepa: 3 }).valid?
# => true
```

### Array example

```ruby
class MyArrayHash < ValidatesStructure::StructuredHash
  key 'apa', Hash, presence: true do
    key 'bepa', Array, presence: true do
      value Integer, presence: true
    end
  end
end

MyArrayHash.new(apa: { bepa: [1, 2, 3] }).valid?
# => true
```

### Compound example

```ruby
class MyInnerHash < ValidatesStructure::StructuredHash
    key 'bepa', Integer, presence: true
end

class MyOuterHash < ValidatesStructure::StructuredHash
  key 'apa', MyInnerHash, presence: true
end

MyInnerHash.new(apa: { bepa: 3 }).valid?
# => true
```

### Custom validation example

```ruby
class MyCustomHash < ValidatesStructure::StructuredHash
  key 'apa', Integer, presence: true, with: :validate_odd

  def validate_odd(attribute)
    errors.add attribute, "can't be even." if self[attribute].even?
  end
end

MyCustomHash.new(apa: 3).valid?
# => true
```

### Custom validator example

```ruby
class OddValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    record.errors.add attribute, "can't be even." if value.even?
  end
end

class MyValidatorHash < ValidatesStructure::StructuredHash
  key 'apa', Integer, odd: true
end

MyValidatorHash.new(apa: 3).valid?
# => true
```


Documentation
-------------
This documentation is about the modules, classes, methods and options of ValidatesStructure. For documentation on ActiveModel::Validations see [the ActiveModel documentation.](http://apidock.com/rails/ActiveModel/Validations/ClassMethods/validates)

### ValidatesStructure::StructuredHash

#### self.key(index, klass, validations={}, &block)
Sets up a requirement on the form ```'index' => klass``` that are validated with _validations_ and containing children on the form specified in _&block_.

**Parameters**

_index_ - The string or symbol by which to retrieve the value

_klass_ - The required class of the value. If klass is a subclass of ValidatesStructure::StructuredHash then the value is validated as specified in its definition.

_validations_ - A hash with [ActiveModel:Validations](http://api.rubyonrails.org/classes/ActiveModel/Validations/HelperMethods.html) on the same format as for the [validates](http://apidock.com/rails/ActiveModel/Validations/ClassMethods/validates) method.

_&block_ - A block of nested _key_ and/or _value_ declarations. Only applicable if klass can be accessed using []= eg. Arrays and Hashes.


**Returns**

A String. The current context as the XPath location of the parent or the root '//'.


#### self.value(klass, validations={}, &block)
Sets up a requirement like self.key but without an index. Useful for structures that are accessed by a numeric index such as Arrays.

**Parameters**

_klass_ - The required class of the value. If klass is a subclass of ValidatesStructure::StructuredHash then the value is validated as specified in its definition.

_validations_ - A hash with [ActiveModel:Validations](http://api.rubyonrails.org/classes/ActiveModel/Validations/HelperMethods.html) on the same format as for the [validates](http://apidock.com/rails/ActiveModel/Validations/ClassMethods/validates) method.

_&block_ - A block of nested _key_ and/or _value_ declarations. Only applicable if klass can be accessed using []= eg. Arrays and Hashes.


**Returns**

A String. The current context as the XPath location of the parent or the root '//'.


**Gotcha**

Using several value declarations will merge the validations into a single validation. The following code would require each element of the Array 'apa' to be both an Integer and a String (and verify presence twice).

```ruby
class MySimpleHash < ValidatesStructure::StructuredHash
  key 'apa', Array do
  	value Integer, presence: true
  	value String, presence: true
  end
end
```


#### []=(key)
Allows you to access your hash using either normal indexes (```my_hash[:apa][:bepa][3]```) or XPath strings (```my_hash['//apa/bepa[3]']```). You are free to use strings, symbols or integers for indexes (```my_hash['apa']['bepa'][:3]```).

**Paramenters**

_key_ - The index or XPath to lookup.

**Returns**

The value of the supplied key.


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