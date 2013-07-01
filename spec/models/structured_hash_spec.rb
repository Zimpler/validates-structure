require 'spec_helper'

describe 'An simple instance of StructuredHash' do
  class MyHash < ValidatesStructure::StructuredHash
    key 'apa', Integer, presence: true
  end


  describe 'given a hash' do
    before :each do
      @hash = { apa: 1 }
      @mine = MyHash.new @hash
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
      @mine = MyHash.new @json
    end

    it 'should have the original json accessible' do
      @mine.raw.should eq(@json)
    end

    it 'should have the hash items accessible through array lookup syntax' do
      @mine[:apa].should eq 1
    end
  end

end
