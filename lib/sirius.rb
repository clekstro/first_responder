require "sirius/version"
require "sirius/object_from_json"
require "sirius/object_from_xml"
require 'virtus'
require 'aequitas'

module Sirius
  FORMATS = [:json, :xml]

  def initialize(format=:json, serialized)
    @format = ensure_format(format)
  end

  def ensure_format(fmt)
    return fmt if FORMATS.include?(fmt)
    raise UnknownSerializationFormat
  end

  def self.included base
    base.extend Virtus
    base.extend Aequitas
    base.extend Sirius::Exceptions
  end

  module Exceptions
    class UnknownSerializationFormat < Exception; end
  end

end
