require_relative "schema_imageable/schema"
require "byebug"

module SchemaImageable
  VERSION = "0.1.0"

  def self.generate(path, **options)
    Schema.new(path, options).generate
  end
end

module ActiveRecord
  class Schema
    def self.define(_, &block)
      class_variable_set("@@_schema_proc", block.to_proc)
    end

    def self.schema_proc
      class_variable_get("@@_schema_proc")
    end
  end
end
