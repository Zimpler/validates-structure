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

    it 'should respond with "3" to "[:apa][:bepa]"' do
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


describe 'A compound instance of StructuredHash' do
  class MyInnerHash < ValidatesStructure::StructuredHash
      key 'bepa', Integer, presence: true, numericality: true
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
end