# frozen_string_literal: true

source "https://rubygems.org"

gemspec

# ambassadors is not published to RubyGems; resolve it via git.
gem "ambassadors", git: "https://github.com/meetcleo/ambassadors.git"

group :development do
  gem "rake", "~> 13.0"
  gem "rubocop", ">= 1.21"
  gem "rubocop-minitest", ">= 0.38"
  gem "rubocop-rake"
end

group :development, :test do
  gem "debug", "~> 1.11"
end

group :test do
  gem "activerecord", "~> 8.1"
  gem "activesupport", "~> 8.1"
  gem "minitest", ">= 5.27.0"
  gem "mocha", ">= 2.8.2"
  gem "sqlite3", "~> 2.8"
end
