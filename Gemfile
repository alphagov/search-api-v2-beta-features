source "https://rubygems.org"

gem "rails", "8.1.2"

gem "bootsnap"
gem "google-cloud-discovery_engine-v1beta"
gem "google-cloud-storage"
gem "govuk_app_config"
gem "plek"
gem "prometheus-client"
gem "railties"

group :test do
  gem "climate_control"
  gem "grpc_mock"
  gem "json_schemer"
  gem "simplecov", require: false
  gem "timecop"
end

group :development, :test do
  gem "brakeman", require: false
  gem "govuk_test"
  gem "pry-byebug"
  gem "rspec-rails"
  gem "rubocop-govuk"
end
