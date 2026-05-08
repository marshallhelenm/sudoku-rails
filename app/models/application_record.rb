class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
  require "json"
  require "byebug"
  require "matrix"
end
