require 'active_model'
require 'active_model'
require 'active_support/core_ext'
require 'json'

module ValidatesStructure
  class StructuredHash
    include ActiveModel::Validations

    attr_reader :raw

    class_attribute :context, instance_writer: false
    class_attribute :keys, instance_writer: false


    def initialize(hash_or_json={})
      @init_errors = {}
      @hash = {}

      @raw = hash_or_json
      if hash_or_json.is_a? String
        @hash = JSON.parse(hash_or_json).with_indifferent_access
      elsif hash_or_json.is_a? Hash
        @hash = hash_or_json.with_indifferent_access
      else
        @init_errors['//'] = "expected a String or a Hash but got a #{hash_or_json.class}."
      end

      validate_keys if @init_errors.empty?
    end

    def self.key(key, klass, validations={}, &block)
      # Make sure we use the subclass' variables
      unless self.context
        self.context = '//'
      end

      unless self.keys
        self.keys = {}
      end

      if self.context == '//'
        self.context += "#{key}" 
      else
        self.context += "/#{key}"
      end

      self.keys[self.context] = klass
      validations.merge!(klass: { klass: klass })
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

    def self.value(klass, validations={}, &block)
      validations.merge!(klass: { klass: klass })
      validates self.context, enumerable: validations

      self.context += '[*]'

      if block_given?
        yield
      end

      self.context = self.context.chomp('[*]')
    end

    def read_attribute_for_validation(key)
      key.to_s.scan(/\w+/i).reduce(@hash) { |dict, k| dict[k] }
    end    

    def [](key)
      read_attribute_for_validation key.to_s
    end

    def valid?(context=nil)
      super(context)
      copy_init_errors
      errors.empty?
    end

    private 

    def copy_init_errors
      @init_errors.each { |attribute, text| self.errors.add attribute, text }
    end

    def validate_keys(struct=@hash, cont='/')
      if keys[cont] && keys[cont] < StructuredHash
        # Leave validation to the StructuredHash
        structured_hash = keys[cont].new(struct)
        if !structured_hash.valid?
          error_desc = []
          structured_hash.errors.each do |a, m|
            error_desc << "#{a} #{m}"
          end
          @init_errors[cont] = error_desc.join('\n')
        end
      elsif struct.is_a? Hash
        struct.each do |key, value|
          cont = "#{cont}/#{key}"
          @init_errors[cont] = "is not a valid key in #{self.class}." if !keys.include?(cont)
          validate_keys value, cont
          cont = cont.chomp("/#{key}")
        end
      elsif struct.is_a? Array
        struct.each do |entry|
          validate_keys entry, "#{cont}[*]"
        end
      end
    end

    class KlassValidator < ActiveModel::EachValidator
      def validate_each(record, attribute, value)
        return if value.nil? # don't check class if nil
        klass = options[:klass]

        if klass < ValidatesStructure::StructuredHash
          # Don't validate class if a subclass of Structured Hash
          # This is taken care of in validate_keys.
        elsif !(value.class <= klass)
          record.errors.add attribute, "has class \"#{value.class}\" but should be a \"#{klass}\"."
        end
      end
    end

    class EnumerableValidator < ActiveModel::EachValidator
      # Validates each value in an enumerable class using ActiveModel validations.
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
end