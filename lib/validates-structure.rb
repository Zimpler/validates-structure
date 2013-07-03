require 'active_model'
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
      unless self.context
        self.context = '//'
      end

      if self.context == '//'
        self.context += "#{key}" 
      else
        self.context += "/#{key}"
      end

      validations.merge!(type: { type: type })
      validates self.context, validations

      if block_given?
        yield
      end

      if self.context == "//#{key}"
        self.context = self.context.chomp("#{key}")
      else
        self.context = self.context.chomp("/#{key}")
      end
    end

    def self.value(type, validations, &block)
      validations.merge!(type: { type: type })
      validates self.context, enumerable: validations

      self.context += '[*]'
      if block_given?
        yield
      end
      self.context = self.context.chomp('[*]')
    end

    def read_attribute_for_validation(key)
      key.scan(/\w+/i).reduce(@hash) { |dict, k| dict[k] }
    end    

    def [](key)
      read_attribute_for_validation key.to_s
    end

    class TypeValidator < ActiveModel::EachValidator
      def validate_each(record, attribute, value)
        type = options[:type]
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

    class EnumerableValidator < ActiveModel::EachValidator
      # Validates each value in an enumerable type using ActiveModel validations.
      # Adapted from a snippet by Milovan Zogovic (http://stackoverflow.com/a/12744945)
      def validate_each(record, attribute, values)
        [values].flatten.each_with_index do |value, index|
          options.each do |key, args|
            validator_options = { attributes: attribute }
            validator_options.merge!(args) if args.is_a?(Hash)

            next if value.nil? && validator_options[:allow_nil]
            next if value.blank? && validator_options[:allow_blank]

            validator_class_name = "ValidatesStructure::StructuredHash::#{key.to_s.camelize}Validator"
            validator_class = begin
              validator_class_name.constantize
            rescue NameError
              "ActiveModel::Validations::#{validator_class_name}".constantize
            end

            validator = validator_class.new(validator_options)
            validator.validate_each(record, attribute + "[#{index}]", value)
          end
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