source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.5.3'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.2.3'
gem 'inherited_resources', '~> 1.9'
gem 'haml', '~> 5.1.0'
gem 'websocket-extensions'

############################
# Storage
gem 'mysql2', '~> 0.5.0'
#gem 'sqlite3'
gem 'seed_dump', '~> 3.3'

# Use Puma as the app server
gem 'puma', '~> 3.11'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'mini_racer', platforms: :ruby

# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.2'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'

# Use Redis adapter to run Action Cable in production
gem 'redis', '~> 4.0'
gem 'redis-rails', '~> 5.0'
gem 'redis-store', '~> 1.6'
gem 'redis-namespace', '~> 1.6'

gem 'sidekiq', '~> 5.2'
gem 'delayed_job', '~> 4.1.8'
gem 'delayed_job_active_record', '~> 4.1.4'

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'


############################################
# Assets

gem 'rmagick', '~> 3.1'
gem 'carrierwave', '~> 1.3'
gem 'carrierwave_direct'


############################################
# Scraping

gem 'mechanize'
gem 'nokogiri', '~> 1.10'

# Use ActiveStorage variant
# gem 'mini_magick', '~> 4.8'

# Use Capistrano for deployment
group :development do
  gem 'ed25519'
  gem 'bcrypt_pbkdf'
  gem 'capistrano-rails'
  gem 'capistrano-rvm'
  gem 'capistrano-bundler'
  gem 'capistrano-passenger'
  gem 'capistrano3-puma'
end

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.1.0', require: false

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '>= 3.0.5', '< 3.2'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

group :test do
  gem 'rspec'
  gem 'rspec-rails'
  #gem 'rspec-solr'
  gem 'rspec_junit_formatter'

  gem 'factory_bot'
  gem 'factory_bot_rails'

  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '>= 2.15'
  gem 'selenium-webdriver'
  # Easy installation and use of chromedriver to run system tests with Chrome
  gem 'chromedriver-helper'
end

group :development, :test do
  gem 'pry'
  gem 'pry-nav'
  gem 'pry-rails'

  # gem 'webrat'
  gem 'byebug'

  # gem 'rails_best_practices'

  gem 'mailcatcher'
end

gem 'actionview-encoded_mail_to'

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
gem 'geo_ip'

#############################
# Shopping

gem 'solidus', '~> 2.8.4'
gem 'solidus_auth_devise', '~> 2.2.0'
gem 'solidus_reports', github: 'solidusio-contrib/solidus_reports'
gem 'solidus_marketplace'
gem 'solidus_gateway', '~> 1.3.0'

##############################
#Bootstrap

gem 'bootstrap-sass'