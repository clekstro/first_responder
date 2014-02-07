require "first_responder/version"
require "virtus"
require "active_model"
require "active_support/core_ext/hash"
require "active_support/core_ext/hash/indifferent_access"
require "active_support/inflector"
require "json"

module FirstResponder
  VALID_FORMATS = [:json, :xml]

  module InstanceMethods

    # Every instance must instantiate itself with a format and corresponding
    # data. Given that information, formats are validated, data is parsed using
    # that format, after which the attributes defined on the class are set to
    # the hash value at the defined location.

    def initialize(fmt=nil, data)
      @format = ensure_format(fmt) if fmt
      @data = data.is_a?(Hash) ? data : deserialize(data, fmt)
      map_attrs
    end

    def valid?(execute=true)
      return true if all_attributes_valid?
      proc_on_invalid.call(@data, errors) if execute
      return no_nesting? ? super : false
    end

    def invalid?(execute=true)
      !valid?(execute)
    end

    private

    def no_nesting?
      nested_validations.empty?
    end

    def map_attrs
      required_attributes.each do |attr_hash|
        attr = attr_hash.keys.first
        value = extract_attribute_value(attr_hash, attr)
        send("#{attr}=", value)
      end
    end

    def ensure_format(fmt)
      raise UnknownFormatError unless VALID_FORMATS.include?(fmt)
    end

    def all_attributes_valid?
      nested_validations.any? &&
        nested_validations.all? { |attr| eval("#{attr}.valid?") }
    end

    def required_attributes
      self.class.required_attributes
    end

    def nested_validations
      self.class.nested_validations
    end

    def proc_on_invalid
      self.class.proc_on_invalid || Proc.new {}
    end

    def deserialize(data, format)
      raise MissingDataError if data == ''
      return JSON.parse(data) if format == :json
      Hash.from_xml(data) if format == :xml
    end

    # Currently have to use eval to access @data at nested array object
    # attr_hash[attr] is String at this point:
    # "['foo']['bar']['baz']"

    def extract_attribute_value(attr_hash, attr)
      return @data if @data.is_a?(Array)
      attr_location = (attr_hash[attr] || "['#{attr.to_s}']")
      hash_location = self.class.first_responder_root + attr_location
      eval("@data.with_indifferent_access#{hash_location}")
    end
  end

  module ClassMethods
    def required_attributes
      @required_attributes ||= []
    end

    def nested_validations
      @nested_validations ||= []
    end

    def first_responder_root
      @first_responder_root ||= ""
    end

    def root(node)
      @first_responder_root = node
    end

    def proc_on_invalid
      @proc_on_invalid
    end

    def when_invalid(&blk)
      @proc_on_invalid = blk
    end

    def default_validations
      { presence: true }
    end

    def requires(attr, type, opts={})
      add_to_required(attr, opts)
      add_to_nested(attr, type)
      validates attr, default_validations.merge(opts)
      attribute attr, type, opts
    end

    def add_to_required(attr, opts)
      first_responder_opts = opts.extract!(:at)[:at]
      required_attributes << Hash[attr, first_responder_opts]
    end

    def add_to_nested(attr, type)
      return if type.is_a? Array
      nested_validations << attr if type.ancestors.include?(FirstResponder)
    end

  end

  module Exceptions
    class UnknownFormatError < Exception; end
    class MissingDataError < Exception; end
  end

  def self.included(base)
    base.send(:include, Virtus.model)
    base.send(:include, ActiveModel::Validations)
    base.send(:include, InstanceMethods)
    base.extend(ClassMethods)
    base.extend(Exceptions)
  end
end
