require 'active_model'
require 'active_support/core_ext'
require 'json'
require 'securerandom'

module ValidatesStructure

  class Validator
    include ActiveModel::Validations

    class_attribute :keys, instance_writer: false
    class_attribute :values, instance_writer: false
    class_attribute :nested_validators, instance_writer: false

    attr_accessor :keys

    def initialize(hash)
      self.class.initialize_class_attributes
      self.keys = []

      return unless hash.is_a?(Hash)

      hash.each do |key, value|
        self.keys << key.to_s
        send "#{key}=", value if respond_to? "#{key}="
      end
    end

    def self.key(key, klass, validations={}, &block)
      initialize_class_attributes
      key = key.to_s

      if klass.class != Class
        raise ArgumentError.new("Types must be given as classes")
      end
      unless @nested_array_key.nil?
        raise ArgumentError.new("Key can not only appear within a block of a key of type Array")
      end
      if keys.include?(key)
        raise ArgumentError.new("Dublicate key \"#{key}\"")
      end

      keys << key
      attr_accessor key

      validations = prepare_validations(klass, validations, &block)
      validates key, validations

      nest_dsl(klass, key, &block)
    end

    def self.value(klass, validations={}, &block)
      initialize_class_attributes

      if klass.class != Class
        raise ArgumentError.new("Types must be given as classes")
      end
      if @nested_array_key.nil?
        raise ArgumentError.new("Value can only appear within the block of a key of Array type")
      end
      if values[@nested_array_key]
        raise ArgumentError.new("Value can only appear once within a block")
      end
      values[@nested_array_key] = klass

      validations = prepare_validations(klass, validations, &block)
      validates @nested_array_key, enumerable: validations
      nest_dsl(klass, @nested_array_key, &block)
    end

    def self.human_attribute_name(attr, *)
      "/#{attr}"
    end

    validate do
      (keys - self.class.keys).each do |key|
        errors.add(key, "is not a known key")
      end
    end

  protected

    def self.initialize_class_attributes
      self.keys ||= []
      self.values ||= {}
      self.nested_validators ||= {}
    end

    def self.prepare_validations(klass, validations, &block)
      validations = validations.dup
      validations[:klass] = { klass: (klass.ancestors.include?(Validator) ? Hash : klass) }
      unless validations[:allow_nil] == true || validations[:allow_blank] == true
        validations[:not_nil] = true
      end
      validations[:nested] = true if block_given? || klass.ancestors.include?(Validator)
      validations
    end

    def self.nest_dsl(klass, key, &block)
      if klass.ancestors.include?(Validator)
        self.nested_validators[key] = klass
      elsif block_given?
        case
        when klass == Hash
          klass_name = "Annonimous#{ key.to_s.camelize }Validator#{SecureRandom.uuid.tr('-','')}"
          const_set(klass_name, Class.new(self.superclass))
          validator = const_get(klass_name)
          validator.instance_eval(&block)
          self.nested_validators[key] = validator
        when klass == Array
          @nested_array_key = key
          yield
          @nested_array_key = nil
        else
          raise ArgumentError.new("Didn't expect a block for the type \"#{klass}\"")
        end
      end
    end

    def self.model_name
      ActiveModel::Name.new(self, nil, "temp")
    end

    class Boolean
    end

    class KlassValidator < ActiveModel::EachValidator
      def validate_each(record, attribute, value)
        return if value.nil?
        klass = options[:klass]
        if klass == Boolean
          unless value.is_a?(TrueClass) || value.is_a?(FalseClass)
            record.errors.add attribute, "has class \"#{value.class}\" but should be boolean"
          end
        elsif !(value.is_a?(klass))
          record.errors.add attribute, "has class \"#{value.class}\" but should be a \"#{klass}\""
        end
      end
    end

    class NotNilValidator < ActiveModel::EachValidator
      def validate_each(record, attribute, value)
        if value.nil?
          record.errors.add attribute, "must not be nil"
        end
      end
    end

    class NestedValidator < ActiveModel::EachValidator
      def validate_each(record, attribute, value)
        return unless value.is_a?(Hash)
        return if record.errors.keys.map(&:to_s).include?(attribute)

        validator = record.class.nested_validators[attribute]
        return if validator.nil?

        nested = validator.new(value)
        nested.valid?
        nested.errors.each do |nested_attribute, message|
          record.errors.add("#{attribute}/#{nested_attribute}", message)
        end
      end
    end

    class EnumerableValidator < ActiveModel::EachValidator
      # Validates each value in an enumerable class using ActiveModel validations.
      # Adapted from a snippet by Milovan Zogovic (http://stackoverflow.com/a/12744945)
      def validate_each(record, attribute, values)
        return unless values.respond_to?(:each_with_index)
        values.each_with_index do |value, index|
          options.each do |key, args|
            validator_options = { attributes: attribute }
            validator_options.merge!(args) if args.is_a?(Hash)

            next if value.nil? && validator_options[:allow_nil]
            next if value.blank? && validator_options[:allow_blank]
            next if key.to_s == "allow_nil"
            next if key.to_s == "allow_blank"

            validator_class_name = "#{key.to_s.camelize}Validator"
            validator_class = self.class.parent.const_get(validator_class_name)
            validator = validator_class.new(validator_options)

            # TODO: There should be a better way!
            tmp_record = record.dup
            validator.validate_each(tmp_record, attribute, value)
            tmp_record.errors.each do |nested_attribute, error|
              indexed_attribute = nested_attribute.to_s.sub(/^#{attribute}/, "#{attribute}[#{index}]")
              record.errors.add(indexed_attribute, error)
            end
          end
        end
      end
    end
  end
end
