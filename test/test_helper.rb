# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "ambassadors/pagination"

require "active_support"
require "active_support/test_case"
require "minitest/autorun"
require "mocha/minitest"

# Mirror the test helper convention from the ambassadors gem.
module ActiveSupport
  class TestCase
    def with_test_table(table_name, row_options, &block)
      conn = ActiveRecord::Base.connection
      conn.create_table(table_name, temporary: true, force: true) do |t|
        row_options.each do |(name, opts_hash)|
          t.public_send(opts_hash[:type], name, **opts_hash.except(:type))
        end
      end
      block.call
    ensure
      conn.drop_table(table_name, if_exists: true)
    end
  end
end
