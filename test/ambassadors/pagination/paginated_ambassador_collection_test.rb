# frozen_string_literal: true

require "test_helper"

module Ambassadors
  module Pagination
    class PaginatedAmbassadorCollectionTest < ActiveSupport::TestCase
      # --- constructor / page window ---

      test "#initialize when current_page is below 1 coerces to page 1" do
        enumerable = stub_enumerable([1, 2, 3])
        collection = PaginatedAmbassadorCollection.new(enumerable, current_page: 0, per_page: 10)

        assert_equal 1, collection.current_page
      end

      test "#initialize when current_page is a string coerces to integer" do
        enumerable = stub_enumerable([1, 2, 3])
        collection = PaginatedAmbassadorCollection.new(enumerable, current_page: "2", per_page: 10)

        assert_equal 2, collection.current_page
      end

      # --- #page ---

      test "#page returns a new PaginatedAmbassadorCollection" do
        enumerable = stub_enumerable([])
        collection = PaginatedAmbassadorCollection.new(enumerable, per_page: 10)

        result = collection.page(2)

        assert_instance_of PaginatedAmbassadorCollection, result
      end

      test "#page returns a collection for the requested page number" do
        enumerable = stub_enumerable([])
        collection = PaginatedAmbassadorCollection.new(enumerable, per_page: 10)

        result = collection.page(3)

        assert_equal 3, result.current_page
      end

      test "#page preserves the per_page size" do
        enumerable = stub_enumerable([])
        collection = PaginatedAmbassadorCollection.new(enumerable, per_page: 15)

        result = collection.page(2)

        assert_equal 15, result.limit_value
      end

      # --- #per ---

      test "#per returns a new PaginatedAmbassadorCollection" do
        enumerable = stub_enumerable([])
        collection = PaginatedAmbassadorCollection.new(enumerable, per_page: 10)

        result = collection.per(5)

        assert_instance_of PaginatedAmbassadorCollection, result
      end

      test "#per returns a collection with the new per_page size" do
        enumerable = stub_enumerable([])
        collection = PaginatedAmbassadorCollection.new(enumerable, per_page: 10)

        result = collection.per(5)

        assert_equal 5, result.limit_value
      end

      test "#per preserves the current page number" do
        enumerable = stub_enumerable([])
        collection = PaginatedAmbassadorCollection.new(enumerable, current_page: 3, per_page: 10)

        result = collection.per(5)

        assert_equal 3, result.current_page
      end

      # --- Kaminari interface ---

      test "#limit_value returns the per_page size" do
        enumerable = stub_enumerable([])
        collection = PaginatedAmbassadorCollection.new(enumerable, per_page: 20)

        assert_equal 20, collection.limit_value
      end

      test "#offset_value returns (page - 1) * per_page" do
        enumerable = stub_enumerable([])
        collection = PaginatedAmbassadorCollection.new(enumerable, current_page: 3, per_page: 10)

        assert_equal 20, collection.offset_value
      end

      test "#total_count delegates to the unscoped enumerable count" do
        enumerable = stub_enumerable(Array.new(42))
        collection = PaginatedAmbassadorCollection.new(enumerable, per_page: 10)

        assert_equal 42, collection.total_count
      end

      test "#total_pages returns the correct page count" do
        enumerable = stub_enumerable(Array.new(25))
        collection = PaginatedAmbassadorCollection.new(enumerable, per_page: 10)

        assert_equal 3, collection.total_pages
      end

      test "#total_pages when the collection is empty returns 1" do
        enumerable = stub_enumerable([])
        collection = PaginatedAmbassadorCollection.new(enumerable, per_page: 10)

        assert_equal 1, collection.total_pages
      end

      test "#next_page when on a middle page returns the next page number" do
        enumerable = stub_enumerable(Array.new(30))
        collection = PaginatedAmbassadorCollection.new(enumerable, current_page: 2, per_page: 10)

        assert_equal 3, collection.next_page
      end

      test "#next_page when on the last page returns nil" do
        enumerable = stub_enumerable(Array.new(20))
        collection = PaginatedAmbassadorCollection.new(enumerable, current_page: 2, per_page: 10)

        assert_nil collection.next_page
      end

      test "#prev_page when on a middle page returns the previous page number" do
        enumerable = stub_enumerable(Array.new(30))
        collection = PaginatedAmbassadorCollection.new(enumerable, current_page: 2, per_page: 10)

        assert_equal 1, collection.prev_page
      end

      test "#prev_page when on page 1 returns nil" do
        enumerable = stub_enumerable(Array.new(30))
        collection = PaginatedAmbassadorCollection.new(enumerable, current_page: 1, per_page: 10)

        assert_nil collection.prev_page
      end

      test "#out_of_range? when the page is within range returns false" do
        enumerable = stub_enumerable(Array.new(30))
        collection = PaginatedAmbassadorCollection.new(enumerable, current_page: 2, per_page: 10)

        refute_predicate collection, :out_of_range?
      end

      test "#out_of_range? when the page exceeds total pages returns true" do
        enumerable = stub_enumerable(Array.new(10))
        collection = PaginatedAmbassadorCollection.new(enumerable, current_page: 99, per_page: 10)

        assert_predicate collection, :out_of_range?
      end

      # --- #metadata ---

      test "#metadata returns a Metadata instance" do
        enumerable = stub_enumerable([])
        collection = PaginatedAmbassadorCollection.new(enumerable, per_page: 10)

        assert_instance_of Metadata, collection.metadata
      end

      test "#metadata reflects the current page state" do
        enumerable = stub_enumerable(Array.new(30))
        collection = PaginatedAmbassadorCollection.new(enumerable, current_page: 2, per_page: 10)

        meta = collection.metadata

        assert_equal 2,  meta.current_page
        assert_equal 10, meta.per_page
        assert_equal 30, meta.total_count
        assert_equal 3,  meta.total_pages
      end

      # --- load protection with Array enumerables ---

      test "#each when paginated only yields the items for the current window" do
        entities = (1..10).map { |i| stub("entity", to_ambassador: stub("ambassador_#{i}", value: i)) }
        collection = PaginatedAmbassadorCollection.new(entities, current_page: 2, per_page: 3)

        values = collection.map(&:value)

        assert_equal [4, 5, 6], values
      end

      test "#total_count when called does not iterate over the collection" do
        # Verifies that metadata retrieval never triggers a full load.
        enumerable = [1, 2, 3, 4, 5]
        collection = PaginatedAmbassadorCollection.new(enumerable, per_page: 2)
        enumerable.expects(:each).never

        collection.total_count
      end

      private

      # Builds a lightweight enumerable stub backed by a real array for count
      # and slice semantics, avoiding any dependency on AR or Ambassador factories.
      def stub_enumerable(array)
        array
      end
    end
  end
end
