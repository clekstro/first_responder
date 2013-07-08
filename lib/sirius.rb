require "sirius/version"
require "virtus"
require "active_model"
require "active_support/core_ext/hash"
require "active_support/inflector"
require "json"

module Sirius
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

    def valid?
      return super if nested_validations.empty?
      true if all_attributes_valid?
    end

    private

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
      nested_validations.all? { |attr| eval("#{attr}.valid?") }
    end

    def required_attributes
      self.class.required_attributes
    end

    def nested_validations
      self.class.nested_validations
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
      attr_location = (attr_hash[attr] || "['#{attr.to_s}']")
      hash_location = self.class.sirius_root + attr_location
      eval("@data#{hash_location}")
    end
  end

  module ClassMethods
    def required_attributes
      @required_attributes ||= []
    end

    def nested_validations
      @nested_validations ||= []
    end

    def sirius_root
      @sirius_root ||= ""
    end

    def root(node)
      @sirius_root = node
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
      sirius_opts = opts.extract!(:at)[:at]
      required_attributes << Hash[attr, sirius_opts]
    end

    def add_to_nested(attr, type)
      nested_validations << attr if type.ancestors.include?(Sirius)
    end

  end

  module Exceptions
    class UnknownFormatError < Exception; end
    class MissingDataError < Exception; end
  end

  def self.included(base)
    base.send(:include, Virtus)
    base.send(:include, ActiveModel::Validations)
    base.send(:include, InstanceMethods)
    base.extend(ClassMethods)
    base.extend(Exceptions)
  end
end
