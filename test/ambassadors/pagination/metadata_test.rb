# frozen_string_literal: true

require "test_helper"

module Ambassadors
  module Pagination
    class MetadataTest < ActiveSupport::TestCase
      test "#next_page when on a middle page returns the next page number" do
        metadata = Metadata.new(current_page: 2, per_page: 10, total_count: 50, total_pages: 5)

        assert_equal 3, metadata.next_page
      end

      test "#next_page when on the last page returns nil" do
        metadata = Metadata.new(current_page: 5, per_page: 10, total_count: 50, total_pages: 5)

        assert_nil metadata.next_page
      end

      test "#next_page when out of range returns nil" do
        metadata = Metadata.new(current_page: 99, per_page: 10, total_count: 50, total_pages: 5)

        assert_nil metadata.next_page
      end

      test "#prev_page when on a middle page returns the previous page number" do
        metadata = Metadata.new(current_page: 3, per_page: 10, total_count: 50, total_pages: 5)

        assert_equal 2, metadata.prev_page
      end

      test "#prev_page when on the first page returns nil" do
        metadata = Metadata.new(current_page: 1, per_page: 10, total_count: 50, total_pages: 5)

        assert_nil metadata.prev_page
      end

      test "#prev_page when out of range returns nil" do
        metadata = Metadata.new(current_page: 99, per_page: 10, total_count: 50, total_pages: 5)

        assert_nil metadata.prev_page
      end

      test "#first_page? when on page 1 returns true" do
        metadata = Metadata.new(current_page: 1, per_page: 10, total_count: 50, total_pages: 5)

        assert_predicate metadata, :first_page?
      end

      test "#first_page? when not on page 1 returns false" do
        metadata = Metadata.new(current_page: 2, per_page: 10, total_count: 50, total_pages: 5)

        refute_predicate metadata, :first_page?
      end

      test "#last_page? when on the last page returns true" do
        metadata = Metadata.new(current_page: 5, per_page: 10, total_count: 50, total_pages: 5)

        assert_predicate metadata, :last_page?
      end

      test "#last_page? when not on the last page returns false" do
        metadata = Metadata.new(current_page: 2, per_page: 10, total_count: 50, total_pages: 5)

        refute_predicate metadata, :last_page?
      end

      test "#out_of_range? when the page exceeds total_pages returns true" do
        metadata = Metadata.new(current_page: 99, per_page: 10, total_count: 50, total_pages: 5)

        assert_predicate metadata, :out_of_range?
      end

      test "#out_of_range? when the page is within range returns false" do
        metadata = Metadata.new(current_page: 2, per_page: 10, total_count: 50, total_pages: 5)

        refute_predicate metadata, :out_of_range?
      end

      test "#to_h includes all pagination fields" do
        metadata = Metadata.new(current_page: 2, per_page: 10, total_count: 50, total_pages: 5)

        result = metadata.to_h

        assert_equal 2,     result[:current_page]
        assert_equal 10,    result[:per_page]
        assert_equal 50,    result[:total_count]
        assert_equal 5,     result[:total_pages]
        assert_equal 3,     result[:next_page]
        assert_equal 1,     result[:prev_page]
        assert_equal false, result[:first_page]
        assert_equal false, result[:last_page]
        assert_equal false, result[:out_of_range]
      end
    end
  end
end
