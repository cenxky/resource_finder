require "resource_finder/version"
require "resource_finder/finder"
require "active_support/concern"

# Use Finder
module ResourceFinder
  extend ActiveSupport::Concern

  included do
    class_attribute :defined_finders, instance_writer: false, default: {}
  end

  private

  def findable(name)
    finder = defined_finders[name]
    finder.call(self, true) if finder
  end

  def _find_resouces
    defined_finders.each do |name, finder|
      record = finder.call(self)
      instance_variable_set("@#{name}", record) if record
    end
  end

  # :nodoc:
  module ClassMethods
    def findable(name, options = {})
      _defined_finders = self.defined_finders
      self.defined_finders = _defined_finders.merge(name => Finder.new(name, options))

      before_action :_find_resouces unless _defined_finders.present?
    end
  end
end
