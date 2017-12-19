require 'spec_helper'
include ValidatesStructure

describe Validator do

  describe "the DSL" do
    it "can define an empty hash" do
      @c = Class.new(ValidatesStructure::Validator) do
      end
    end

    it "accepts both string and symbol for key name" do
      @c = Class.new(ValidatesStructure::Validator) do
        key :a, Integer
        key "b", Integer
      end
      @c.new({ :a => 1, "b" => 2 }).should be_valid
    end

    it "accepts both strings and symbols as keys in the hash" do
      @c = Class.new(ValidatesStructure::Validator) do
        key :a, Integer
        key "b", Integer
      end
      @c.new({ "a" => 1, :b => 2 }).should be_valid
    end

    it "only allows a block if the type is Hash or Array" do
      expect {
        @c = Class.new(ValidatesStructure::Validator) do
          key :a, Integer do
          end
        end
      }.to raise_error ArgumentError
    end

    it "requires classes a types" do
      expect {
        @c = Class.new(ValidatesStructure::Validator) do
          key :a, "integer"
        end
      }.to raise_error ArgumentError
    end

    it "doesn't allow the same key several times" do
      expect {
        @c = Class.new(ValidatesStructure::Validator) do
          key :a, Integer
          key "a", String
        end
      }.to raise_error ArgumentError
    end

    it "doesn't allow value unless the parent is a key of type Array" do
      expect {
        @c = Class.new(ValidatesStructure::Validator) do
          key :a, Hash do
            value String
          end
        end
      }.to raise_error ArgumentError
    end

    it "doesn't allow several values on the same level" do
      expect {
        @c = Class.new(ValidatesStructure::Validator) do
          key :a, Array do
            value String
            value String
          end
        end
      }.to raise_error ArgumentError
    end

    it "doesn't allow a key within a block of a key with type Array" do
      expect {
        @c = Class.new(ValidatesStructure::Validator) do
          key :a, Array do
            key :b, String
          end
        end
      }.to raise_error ArgumentError
    end

    it "doesn't allow nested arrays" do
      expect {
        @c = Class.new(ValidatesStructure::Validator) do
          key :a, Array do
            value Array do
              value String
            end
          end
        end
      }.to raise_error ArgumentError
    end

  end

  describe "type validation of normal types" do
    before do
      @c = Class.new(ValidatesStructure::Validator) do
        key 'a', String, allow_nil: true
      end
    end

    it "validates on values of the same or a decendent type" do
      @c.new({ a: "string" }).should be_valid
      @c.new({ a: Class.new(String).new("string") }).should be_valid
    end

    it "validates on nil value if allow_nil is true" do
      @c.new({ a: nil }).should be_valid
    end

    it "reports error on values of the wrong type" do
      v = @c.new({ a: 5 })
      v.should_not be_valid
      v.errors.full_messages.should eq [
        "/a has class \"Integer\" but should be a \"String\""
      ]
    end
  end

  describe "type validation of boolean types" do
    before do
      @c = Class.new(ValidatesStructure::Validator) do
        key 'a', ValidatesStructure::Validator::Boolean, allow_nil: true
      end
    end

    it "validates on true value" do
      @c.new({ a: true }).should be_valid
    end

    it "validates on false value" do
      @c.new({ a: false }).should be_valid
    end

    it "validates on nil value if allow_nil is true" do
      @c.new({ a: nil }).should be_valid
    end

    it "reports error on values of the wrong type" do
      v = @c.new({ a: "true" })
      v.should_not be_valid
      v.errors.full_messages.should eq [
        "/a has class \"String\" but should be boolean"
      ]
    end
  end

  describe "the not_blank option" do
    before do
      @c = Class.new(ValidatesStructure::Validator) do
        key :a, String
      end
    end

    it "is active when no option is specified" do
      v = @c.new({})
      v.should_not be_valid
      v.errors.full_messages.should eq ["/a must not be empty"]
    end

    it "is invalid when value is nil" do
      v = @c.new({ a: nil })
      v.should_not be_valid
      v.errors.full_messages.should eq ["/a must not be empty"]
    end

    it "is invalid when value is an empty string '   '" do
      v = @c.new({ a: "    " })
      v.should_not be_valid
      v.errors.full_messages.should eq ["/a must not be empty"]
    end

    it "is valid when value not empty" do
      v = @c.new({ a: "    x" })
      v.should be_valid
    end
  end

  describe "the allow_nil option" do
    it "makes the key required if option is missing" do
      @c = Class.new(ValidatesStructure::Validator) do
        key 'a', String
      end
      v = @c.new({})
      v.should_not be_valid
      v.errors.full_messages.should eq ["/a must not be empty"]
    end

    it "makes the key optional if present" do
      @c = Class.new(ValidatesStructure::Validator) do
        key 'a', String, allow_nil: true
      end
      @c.new({}).should be_valid
      @c.new({a: nil}).should be_valid
    end
  end

  describe "the allow_blank option" do
    it "makes the key optional if present" do
      @c = Class.new(ValidatesStructure::Validator) do
        key 'a', String, allow_blank: true
      end
      @c.new({}).should be_valid
      @c.new({a: nil}).should be_valid
      @c.new({a: "   "}).should be_valid
    end
  end


  describe "validation of unknown keys" do
    it "gives error for unknown keys" do
      @c = Class.new(ValidatesStructure::Validator) do
      end
      v = @c.new({ a: 1 })
      v.should_not be_valid
      v.errors.full_messages.should eq ["/a is not a known key"]
    end
  end

  describe "a standard validation" do
    it "is available" do
      @c = Class.new(ValidatesStructure::Validator) do
        key :a, String, presence: true
      end
      @c.new({ a: "string" }).should be_valid
      v = @c.new({ a: "" })
      v.should_not be_valid
      v.errors.full_messages.should eq ["/a can't be blank", "/a must not be empty"]
    end
  end

  describe "a nested hash key" do
    before do
      @c = Class.new(ValidatesStructure::Validator) do
        key :a, Hash, allow_nil: true do
          key :b, String
          key :c, Integer
        end
      end
    end

    it "validates nested keys" do
      v = @c.new({ a: { b: 1, c: 1} })
      v.should_not be_valid
      v.errors.full_messages.should eq [
        "/a/b has class \"Integer\" but should be a \"String\""
      ]
    end

    it "doesn't validate nested keys if the parent key doesn't validate" do
      v = @c.new({ a: 1 })
      v.should_not be_valid
      v.errors.full_messages.should eq [
        "/a has class \"Integer\" but should be a \"Hash\""
      ]
    end

    it "doesn't validate nested keys if the parent key is nil and allow_nil option is true" do
      v = @c.new({ a: nil })
      v.should be_valid
    end
  end

  describe "nested Validator" do
    it "validate the nested keys" do

    end
  end

  describe "an array key" do
    context "with plain values" do
      before do
        @c = Class.new(ValidatesStructure::Validator) do
          key :a, Array, allow_nil: true do
            value String, allow_nil: true
          end
        end
      end

      it "validates a nil value if allow_nil is true" do
        @c.new({ a: nil }).should be_valid
      end

      it "validates an empty array" do
        @c.new({ a: [] }).should be_valid
      end

      it "validates the type of the array" do
        v = @c.new({ a: "string" })
        v.should_not be_valid
        v.errors.full_messages.should eq [
          "/a has class \"String\" but should be a \"Array\""
        ]
      end

      it "validates the type of the array values" do
        @c.new({ a: ["one", "two"] }).should be_valid
        v = @c.new({ a: ["one", 1, 2] })
        v.should_not be_valid
        v.errors.full_messages.should eq [
          "/a[1] has class \"Integer\" but should be a \"String\"",
          "/a[2] has class \"Integer\" but should be a \"String\""
        ]
      end
    end

    context "with nested hash" do
      before do
        @c = Class.new(ValidatesStructure::Validator) do
          key :a, Array, allow_nil: true do
            value Hash, allow_nil: true do
              key :b, String
            end
          end
        end
      end

      it "validates a nil value if allow_nil is true" do
        @c.new({ a: nil }).should be_valid
      end

      it "validates an empty array" do
        @c.new({ a: [] }).should be_valid
      end

      it "validates the type of the nested" do
        v = @c.new({ a: "string" })
        v.should_not be_valid
        v.errors.full_messages.should eq [
          "/a has class \"String\" but should be a \"Array\""
        ]
      end

      it "validates the type of the nested hashes" do
        @c.new({ a: [{ b: "one"}, {b: "two"}] }).should be_valid
        v = @c.new({ a: [{}, 1, 2] })
        v.should_not be_valid
        v.errors.full_messages.should eq [
          "/a[0]/b must not be empty",
          "/a[1] has class \"Integer\" but should be a \"Hash\"",
          "/a[2] has class \"Integer\" but should be a \"Hash\""
        ]
      end
    end

    context "with parallel nested hashes" do
      before do
        @c = Class.new(ValidatesStructure::Validator) do
          key :a, Array do
            value Hash do
              key :c, String
            end
          end
          key :b, Array do
            value Hash do
              key :c, Integer
            end
          end
        end
      end

      it "validates each hash without interference from the other" do
        #@c.new({ a: [{ c: "one"}], b: [{ c: 3 }] }).should be_valid
        v = @c.new({ a: [{ c: 3}], b: [{ c: "one" }] })
        v.should_not be_valid
        v.errors.full_messages.should eq [
          "/a[0]/c has class \"Integer\" but should be a \"String\"",
          "/b[0]/c has class \"String\" but should be a \"Integer\""
        ]
      end
    end

  end

  describe 'A compound instance of Validator' do
    before do
      nested_validator = Class.new(ValidatesStructure::Validator) do
        key :c, String
      end
      @c = Class.new(ValidatesStructure::Validator) do
        key :a, nested_validator, allow_nil: true
        key :b, String
      end
    end

    it "validates across both validators" do
      @c.new({ a: { c: "one" }, b: "two" }).should be_valid
    end

    it "validates a nil value if allow_nil is true" do
      @c.new({ a: nil, b: "one" }).should be_valid
    end

    it "merges errors across both validators" do
      v = @c.new({ a: { c: 1 }, b: 2 })
      v.should_not be_valid
      v.errors.full_messages.should eq [
        "/a/c has class \"Integer\" but should be a \"String\"",
        "/b has class \"Integer\" but should be a \"String\""
      ]
    end
  end

  describe 'A Validator with a custom validation' do
    class OddValidator < ActiveModel::EachValidator
      def validate_each(record, attribute, value)
        record.errors.add attribute, "can't be even" if value.even?
      end
    end

    before do
      @c = Class.new(ValidatesStructure::Validator) do
        key :a, Integer, odd: true
      end
    end

    it "uses the custom validation" do
      v = @c.new({ a:  2 })
      v.should_not be_valid
      v.errors.full_messages.should eq [
        "/a can't be even"
      ]
    end
  end

  describe 'With a namespaced validator' do
    module V3
      module Annoying
        class MyValidatorBase < ValidatesStructure::Validator
          class MyOddValidator < ActiveModel::EachValidator
            def validate_each(record, attribute, value)
              record.errors.add attribute, "can't be even" if value.even?
            end
          end
        end

        class MyValidator < MyValidatorBase
          key :a, Integer, my_odd: true
          key :nested, Hash, allow_nil: true do
            key :b, Integer, my_odd: true
          end
        end
      end
    end

    it "uses the custom validation" do
      v = V3::Annoying::MyValidator.new({ a:  2 , nested: { b: 2 }})
      v.should_not be_valid
      v.errors.full_messages.should eq [
        "/a can't be even",
        "/nested/b can't be even"
      ]
    end
  end
end
