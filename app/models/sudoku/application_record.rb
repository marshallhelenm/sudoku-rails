class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
  require "json"
  require "matrix"
end
