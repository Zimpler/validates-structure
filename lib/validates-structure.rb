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
    #include ActiveSupport::Callbacks # Might be useful for initial data molding - future feature?

    attr_reader :raw

    @@structure = {}

    def initialize(hash_or_json)
      @raw = hash_or_json
      if hash_or_json.class == String
        @hash = JSON.parse(hash_or_json).with_indifferent_access
      else
        @hash = hash_or_json.with_indifferent_access
      end
    end

    def self.key(key, type, validations, &block)
      context ||= ""
      set_key(context + "[#{key}]", TypedValidation.new(type, validations))

      if block_given?
        context << "[#{key}]"
        yield
        context.chomp!("[#{key}]")
      end
    end

    def self.value(key, type, validations)
    end

    def read_attributes_for_validation(key)
      @hash[key]
    end

    def [](key)
      @hash[key]
    end

    private

    def self.set_key(key, struct)
      keys = key.scan(/\w+/i)

      s = @@structure
      (0..keys.length-2).each do |i|
        s = s[keys[i]]
      end
      s[keys[keys.length-1]] = struct
    end

    class TypedValidation
      attr_accessor :type, :validations

      def initialize(type, validations)
        @type = type
        @validations = validations
      end
    end

  end
end