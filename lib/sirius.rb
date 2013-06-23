require "sirius/version"
require 'virtus'
require 'active_model'
require 'active_support/core_ext/hash'
require 'json'

module Sirius
  VALID_FORMATS = [:json, :xml]
  OPTIONS = [:at]

  module InstanceMethods
    def initialize(fmt=:json, data)
      @format = ensure_format(fmt)
      @data = deserialize(data, fmt)
      map_attrs
    end

    def ensure_format(fmt)
      raise UnknownFormatError unless VALID_FORMATS.include?(fmt)
    end

    def deserialize(data, format)
      raise MissingDataError if data == ''
      return JSON.parse(data) if format == :json
      Hash.from_xml(data) if format == :xml
    end

    def map_attrs
      self.class.required_attributes.each do |attr|
        send("#{attr}=", @data[attr.to_s])
      end
    end
  end

  module ClassMethods
    def required_attributes
      @@required_attributes ||= []
    end

    def requires(attr, type, opts={})
      supported_opts = opts.slice!(*OPTIONS)
      # required_attributes << Hash.new(attr, supported_opts)
      required_attributes << attr
      validates_presence_of attr
      attribute attr, type, opts
    end  
  end

  module Exceptions
    class UnknownFormatError < Exception; end
    class MissingDataError < Exception; end
  end

  def self.included(base)
    base.send(:include, Virtus)
    base.send(:include, ActiveModel::Validations)
    base.send(:include, Sirius::InstanceMethods)
    base.extend(Sirius::ClassMethods)
    base.extend(Sirius::Exceptions)
  end
end
