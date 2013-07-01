require 'active_model'
require 'active_support/core_ext'
require 'json'

# class Request < ValidatesStructure::StructuredHash
#   key 'apa', Integer, presence: true
#   key 'bepa', Integer, presence: true
#   key 'cepa', Item, presence: true
#   key 'depa', Array, presence: true do
#     value Item presence: true
#   end
# end
#
# class Item < ValidatesStructure::StructuredHash
#   key 'id', Integer, presence: true
#   key 'text', String, length: { min: 10 }
# end
#
# hash = Request.new(request.body)
# hash.valid?
# => false
# hash.errors
# => [...]
# hash[:apa]
# => nil
#
module ValidatesStructure
  class StructuredHash
    include ActiveModel::Validations

    attr_reader :raw

    class_attribute :structure, instance_writer: false
    class_attribute :context, instance_writer: false

    def initialize(hash_or_json)
      @raw = hash_or_json
      if hash_or_json.class == String
        @hash = JSON.parse(hash_or_json).with_indifferent_access
      else
        @hash = hash_or_json.with_indifferent_access
      end
    end

    def self.key(key, type, validations, &block)
      unless self.structure
        self.structure = {} # Don't modify superclass variable
      end

      unless self.context
        self.context = ''
      end

      self.context += "[#{key}]"
      validations.merge!(type: type)
      validates self.context, validations
      #TODO: Add type validator

      if block_given?
        yield
      end

      self.context = self.context.chomp("[#{key}]")
    end

    def self.value(key, type, validations)
      'unimplemented'
    end

    def read_attribute_for_validation(key)
      key.scan(/\w+/i).reduce(@hash) { |dict, k| dict[k] }
    end    

    def [](key)
      @hash[key]
    end

    class TypeValidator < ActiveModel::EachValidator
      def validate_each(record, attribute, value)
        type = options[:with]
        if type < ValidatesStructure::StructuredHash
          structured_hash = type.new(value)
          if !structured_hash.valid?
            error_desc = []
            structured_hash.errors.each do |a, m|
              error_desc << "#{a} #{m}"
            end
            record.errors.add attribute, error_desc.join('\n')
          end
        elsif !(value.class <= type)
          record.errors.add attribute, "has type \"#{value.class}\" but should be a \"#{type}\"."
        end
      end
    end

  end

  class StructureValidator < ActiveModel::Validator
    def validate(record)
        #TODO: validate the hash structure
    end
  end
end