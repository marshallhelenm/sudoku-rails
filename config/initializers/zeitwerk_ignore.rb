# Ignore script-like model file that is not a Rails autoloadable constant.
Rails.autoloaders.main.ignore(Rails.root.join("app/models/main.rb"))
