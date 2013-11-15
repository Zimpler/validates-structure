require 'spec_helper'

describe 'A simple instance of StructuredHash' do
  class MySimpleHash < ValidatesStructure::StructuredHash
    key 'apa', Integer, presence: true
  end

  describe 'given a hash' do
    before :each do
      @hash = { apa: 1 }
      @mine = MySimpleHash.new @hash
    end

    it 'should respond to ActiveModel validation methods' do
      @mine.should respond_to 'valid?'
      @mine.should respond_to 'errors'
    end

    it 'should have the original hash accessible' do
      @mine.raw.should eq(@hash)
    end

    it 'should have the hash items accessible through array lookup syntax (string key)' do
      @mine['apa'].should eq 1
    end

    it 'should have the hash items accessible through array lookup syntax (symbol key)' do
      @mine[:apa].should eq 1
    end
  end

  describe 'given a json string' do
    before :each do
      @json = '{"apa": 1}'
      @mine = MySimpleHash.new @json
    end

    it 'should have the original json accessible' do
      @mine.raw.should eq(@json)
    end

    it 'should have the hash items accessible through array lookup syntax' do
      @mine[:apa].should eq 1
    end
  end

  describe 'given a hash with superfluous keys' do
    it 'should not be valid (empty)' do
      MySimpleHash.new(nil).should_not be_valid
    end

    it 'should not be valid (primitive klass)' do
      MySimpleHash.new(3).should_not be_valid
    end

    it 'should not be valid (simple)' do
      MySimpleHash.new(apa: 1, bepa: 2 ).should_not be_valid
    end

    it 'should not be valid (nested hash)' do
      MySimpleHash.new(apa: { bepa: 2 } ).should_not be_valid
    end

    it 'should not be valid (nested array)' do
      MySimpleHash.new(apa: [2, 3, 4] ).should_not be_valid
    end

    it 'should not be valid (double nested array)' do
      MySimpleHash.new(apa: [[1,2,3], [1,2,3], [1,2,3]] ).should_not be_valid
    end

    it 'should not be valid (array of hashes)' do
      MySimpleHash.new(apa: [{apa: 1}, {bepa: 1}, {cepa: 1}] ).should_not be_valid
    end

    it 'should not be valid (value type)' do
      MySimpleHash.new(apa: "string" ).should_not be_valid
    end
  end
end


describe 'A StructuredHash with Boolean type' do
  class MyBooleanHash < ValidatesStructure::StructuredHash
    key 'apa', Boolean
  end

  it 'accepts true as value' do
    MyBooleanHash.new({apa: true}).should be_valid
  end

  it 'accepts false as value' do
    MyBooleanHash.new({apa: false}).should be_valid
  end

  it 'does not accepts nil as value' do
    MyBooleanHash.new({apa: nil}).should_not be_valid
  end

  it 'does not accept the wrong class' do
    MyBooleanHash.new({apa: 5}).should_not be_valid
  end
end


describe 'A StructuredHash with optional keys' do
  class MyOptionalKeyHash < ValidatesStructure::StructuredHash
    key 'apa', Integer, allow_nil: true
  end

  it 'accepts a value' do
    MyOptionalKeyHash.new({apa: 5}).should be_valid
  end

  it 'accepts nil as a value' do
    MyOptionalKeyHash.new({apa: nil}).should be_valid
  end

  it 'accepts if the key is missing' do
    MyOptionalKeyHash.new({}).should be_valid
  end
end


describe 'A StructuredHash with optional hash' do
  class MyOptionallyHashHash < ValidatesStructure::StructuredHash
    key 'apa', Hash, allow_nil: true
  end

  it 'accepts an empty hash' do
    MyOptionallyHashHash.new({apa: {}}).should be_valid
  end

  it 'accepts nil as a value' do
    MyOptionallyHashHash.new({apa: nil}).should be_valid
  end

  it 'accepts if the key is missing' do
    MyOptionallyHashHash.new({}).should be_valid
  end
end


describe 'A StructuredHash with optional array values' do
  class MyOptionallyArrayHash < ValidatesStructure::StructuredHash
    key 'apa', Array do
      value Integer, allow_nil: true
    end
  end

  it 'accepts an array with values' do
    MyOptionallyArrayHash.new({apa: [1,2]}).should be_valid
  end

  it 'accepts requires an array as the array key is not optional' do
    MyOptionallyArrayHash.new({apa: nil}).should_not be_valid
  end

  it 'accepts an array that includes nil values' do
    MyOptionallyArrayHash.new({apa: [1,nil,2]}).should be_valid
  end

  it 'accepts an empty array' do
    MyOptionallyArrayHash.new({apa: []}).should be_valid
  end
end


describe 'A StructuredHash with mandatory keys' do
  class MyMandatoryKeyHash < ValidatesStructure::StructuredHash
    key 'apa', Integer, presence: true
  end

  it 'accepts a value' do
    MyMandatoryKeyHash.new({apa: 5}).should be_valid
  end

  it 'does not accepts nil as a value' do
    MyMandatoryKeyHash.new({apa: nil}).should_not be_valid
  end

  it 'does not accepts if the key is missing' do
    MyMandatoryKeyHash.new({}).should_not be_valid
  end
end


describe 'A nested instance of StructuredHash' do
  class MyStructuredHash < ValidatesStructure::StructuredHash
    key 'bepa', Hash, presence: true do
      key 'cepa', Integer, presence: true, format: { with: /3/i}
    end
  end

  describe 'given a valid hash' do
    before :each do
      @hash = { bepa: { cepa: 3 } }
      @mine = MyStructuredHash.new @hash
    end

    it 'should respond with "3" to "[:bepa][:cepa]"' do
      @mine[:bepa][:cepa].should eq 3
    end

    it 'should be valid' do
      @mine.should be_valid
    end
  end


  describe 'given an invalid hash' do
    before :each do
      @hash = { bepa: { cepa: 'invalid' } }
      @mine = MyStructuredHash.new @hash
    end

    it 'should not be valid' do
      @mine.should_not be_valid
    end
  end
end


describe 'A StructuredHash containing an array' do
  class MyArrayHash < ValidatesStructure::StructuredHash
    key 'apa', Hash, presence: true do
      key 'bepa', Array, presence: true do
        value Integer, presence: true
      end
    end
  end

  describe 'given a valid hash' do
    before :each do
      @hash = { apa: { bepa: [ 3, 5, 10 ] } }
      @mine = MyArrayHash.new @hash
    end

    it 'should be valid' do
      @mine.should be_valid
    end
  end

  describe 'given an invalid hash' do
    before :each do
      @hash = { apa: { bepa: [ 3, 'invalid', 10 ] } }
      @mine = MyArrayHash.new @hash
    end

    it 'should not be valid' do
      @mine.should_not be_valid
    end
  end
end


describe 'A compound instance of StructuredHash' do
  class MyInnerHash < ValidatesStructure::StructuredHash
      key 'bepa', Integer, presence: true
  end

  class MyOuterHash < ValidatesStructure::StructuredHash
    key 'apa', MyInnerHash, presence: true
  end

  describe 'given a valid hash' do
    before :each do
      @hash = { apa: { bepa: 3 } }
      @mine = MyOuterHash.new @hash
    end

    it 'should be valid' do
      @mine.should be_valid
    end
  end

  describe 'given an invalid hash' do
    before :each do
      @hash = { apa: { bepa: 'invalid' } }
      @mine = MyOuterHash.new @hash
    end

    it 'should not be valid' do
      @mine.should_not be_valid
    end
  end

  describe 'given a hash with superfluous keys' do
    it 'should not be valid' do
      MySimpleHash.new(apa: {bepa: 2}, cepa: 2 ).should_not be_valid
    end
  end
end

describe 'A StructuredHash with a custom validation' do
  class MyCustomHash < ValidatesStructure::StructuredHash
    key 'apa', Integer, presence: true, with: :validate_odd

    def validate_odd(attribute)
      errors.add attribute, "can't be even." if self[attribute].even?
    end
  end

  describe 'given a valid hash' do
    before :each do
      @hash = { apa: 3 }
      @mine = MyCustomHash.new @hash
    end

    it 'should be valid' do
      @mine.should be_valid
    end
  end

  describe 'given an invalid hash' do
    before :each do
      @hash = { apa: 2 }
      @mine = MyCustomHash.new @hash
    end

    it 'should not be valid' do
      @mine.should_not be_valid
    end
  end
end

describe 'A StructuredHash with a custom EachValidator' do
  class OddValidator < ActiveModel::EachValidator
    def validate_each(record, attribute, value)
      record.errors.add attribute, "can't be even." if value.even?
    end
  end

  class MyValidatorHash < ValidatesStructure::StructuredHash
    key 'apa', Integer, odd: true
  end


  describe 'given a valid hash' do
    before :each do
      @mine = MyValidatorHash.new(apa: 3)
    end

    it 'should be valid' do
      @mine.should be_valid
    end
  end

  describe 'given an invalid hash' do
    before :each do
      @mine = MyValidatorHash.new(apa: 4)
    end

    it 'should not be valid' do
      @mine.should_not be_valid
    end
  end
end