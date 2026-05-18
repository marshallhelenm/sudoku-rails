# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

# Add additional assets to the asset load path.
Rails.application.config.assets.paths << Rails.root.join('app', 'assets', 'javascripts')

# Ensure legacy vendor-like scripts are available to javascript_include_tag.
Rails.application.config.assets.precompile += %w[ jquery.fullPage.js ]
