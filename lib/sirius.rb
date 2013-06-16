require "sirius/version"
require 'virtus'
require 'aequitas'

module Sirius
  FORMATS = [:json, :xml]

  module InstanceMethods
    def initialize(format=:json, serialized)
      @format = ensure_format(format)
      @data = deserialize(serialized)
      # set_attributes_for(@data)
    end

    def ensure_format(fmt)
      return fmt if FORMATS.include?(fmt)
      raise UnknownSerializationFormat
    end

    def deserialize(serialized)
      return JSON.parse(serialized) if @format == :json
    end
  end

  module ClassMethods
    include Virtus
    include Aequitas
    def requires(attribute, type, opts={})
      attribute(attribute, type, opts)
    end
  end

  module Exceptions
    class UnknownSerializationFormat < Exception; end
  end

  def self.included base
    base.extend Sirius::Exceptions
    base.send(:include, Sirius::InstanceMethods)
    base.extend Sirius::ClassMethods
  end
end
