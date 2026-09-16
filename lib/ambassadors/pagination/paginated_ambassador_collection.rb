# frozen_string_literal: true

module Ambassadors
  module Pagination
    ##
    # A paginated extension of {::AmbassadorCollection} backed by Kaminari.
    #
    # Applies a page window (limit + offset) directly to the underlying
    # enumerable before records are loaded. For ActiveRecord::Relation
    # enumerables the window is pushed down to SQL, so at most +per_page+
    # rows are loaded per request. This preserves the load-limiting intent
    # of the base collection.
    #
    # Because Rails raises when +find_each+ is called on a scoped relation
    # that already carries a +LIMIT+, this class always uses plain +each+
    # iteration (via {Ambassadors::Iterators::Iterator}) after the window
    # has been applied.
    #
    # Implements the interface expected by Kaminari's view helpers via
    # +Kaminari::PageScopeMethods+.
    #
    # @example Basic usage
    #   collection = PaginatedAmbassadorCollection.new(
    #     User.all,
    #     ambassador_class: UserAmbassador,
    #     current_page: 2,
    #     per_page: 25
    #   )
    #   collection.total_pages  #=> 4
    #   collection.next_page    #=> 3
    #
    # @example Chaining
    #   base = PaginatedAmbassadorCollection.new(User.all, ambassador_class: UserAmbassador)
    #   page_two = base.page(2).per(10)
    class PaginatedAmbassadorCollection < ::AmbassadorCollection
      # Expose class-level DSL: paginates_per, max_paginates_per.
      include Kaminari::ConfigurationMethods

      ##
      # @param enumerable [Enumerable]
      # @param current_page [Integer] 1-based page number (defaults to 1)
      # @param per_page [Integer] records per page (defaults to Kaminari default)
      # @param kwargs [Hash] forwarded to {::AmbassadorCollection}
      def initialize(enumerable, current_page: 1, per_page: Kaminari.config.default_per_page, **kwargs)
        @unscoped_enumerable = enumerable
        @current_page_number = [current_page.to_i, 1].max
        @per_page_size = per_page.to_i
        @collection_kwargs = kwargs

        # Use plain each-iteration: find_each raises when a LIMIT is already present.
        super(windowed_enumerable, iterator: Ambassadors::Iterators::Iterator, **kwargs)
      end

      ##
      # Returns a new collection for the given page number.
      # @param number [Integer]
      # @return [PaginatedAmbassadorCollection]
      def page(number)
        self.class.new(
          @unscoped_enumerable,
          current_page: number,
          per_page: @per_page_size,
          **@collection_kwargs
        )
      end

      ##
      # Returns a new collection with the given page size.
      # @param size [Integer]
      # @return [PaginatedAmbassadorCollection]
      def per(size)
        self.class.new(
          @unscoped_enumerable,
          current_page: @current_page_number,
          per_page: size,
          **@collection_kwargs
        )
      end

      ##
      # The maximum number of records per page (satisfies Kaminari::PageScopeMethods).
      # @return [Integer]
      def limit_value
        @per_page_size
      end

      ##
      # The record offset for the current page (satisfies Kaminari::PageScopeMethods).
      # @return [Integer]
      def offset_value
        (@current_page_number - 1) * @per_page_size
      end

      ##
      # Total number of records across all pages. Issues a COUNT query for
      # ActiveRecord::Relation enumerables - never loads records.
      # @return [Integer]
      def total_count
        @unscoped_enumerable.count
      end

      ##
      # The 1-based page number currently active.
      # @return [Integer]
      def current_page
        @current_page_number
      end

      ##
      # Total number of pages given the current per_page size.
      # @return [Integer]
      def total_pages
        return 1 if total_count.zero?

        (total_count.to_f / limit_value).ceil
      end

      ##
      # @return [Integer, nil] next page number, or nil when on the last page
      def next_page
        current_page + 1 unless last_page? || out_of_range?
      end

      ##
      # @return [Integer, nil] previous page number, or nil when on the first page
      def prev_page
        current_page - 1 unless first_page? || out_of_range?
      end

      ##
      # @return [Boolean]
      def first_page?
        current_page == 1
      end

      ##
      # @return [Boolean]
      def last_page?
        current_page == total_pages
      end

      ##
      # @return [Boolean]
      def out_of_range?
        current_page > total_pages
      end

      ##
      # Pagination metadata for JSON serialisation and programmatic inspection.
      # @return [Metadata]
      def metadata
        Metadata.new(
          current_page: current_page,
          per_page: limit_value,
          total_count: total_count,
          total_pages: total_pages
        )
      end

      private

      def windowed_enumerable
        if defined?(ActiveRecord::Relation) && @unscoped_enumerable.is_a?(ActiveRecord::Relation)
          @unscoped_enumerable.offset(offset_value).limit(limit_value)
        else
          Array(@unscoped_enumerable).slice(offset_value, limit_value) || []
        end
      end
    end
  end
end
