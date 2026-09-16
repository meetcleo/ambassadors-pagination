# frozen_string_literal: true

module Ambassadors
  module Pagination
    ##
    # A paginated extension of {::AmbassadorCollection} backed by Kaminari.
    #
    # Builds a Kaminari-aware scope from the enumerable using +.page(n).per(m)+
    # and delegates all pagination metadata to it. For ActiveRecord::Relation
    # enumerables the window is pushed down to SQL (at most +per_page+ rows
    # loaded per request). For plain enumerables, +Kaminari.paginate_array+
    # is used.
    #
    # Because Rails raises when +find_each+ is called on a relation that already
    # carries a +LIMIT+, this class always uses plain +each+ iteration
    # (via {Ambassadors::Iterators::Iterator}) after the page window is applied.
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
    #
    # @example Class-level default page size
    #   PaginatedAmbassadorCollection.paginates_per 15
    class PaginatedAmbassadorCollection < ::AmbassadorCollection
      extend Forwardable

      # Provides class-level DSL: +paginates_per+, +max_paginates_per+.
      include Kaminari::ConfigurationMethods

      # Delegate Kaminari page-state methods to the underlying Kaminari scope.
      # total_pages is intentionally excluded - see method definition below.
      def_delegators :@kaminari_scope,
                     :current_page, :total_count, :limit_value,
                     :offset_value, :next_page, :prev_page,
                     :first_page?, :last_page?, :out_of_range?

      ##
      # @param enumerable [Enumerable]
      # @param current_page [Integer] 1-based page number (defaults to 1)
      # @param per_page [Integer, nil] records per page (defaults to +paginates_per+ or Kaminari global default)
      # @param kwargs [Hash] forwarded to {::AmbassadorCollection}
      def initialize(enumerable, current_page: 1, per_page: nil, **kwargs)
        @unscoped_enumerable = enumerable
        @collection_kwargs = kwargs
        @kaminari_scope = build_kaminari_scope(
          enumerable,
          current_page: current_page,
          per_page: per_page || self.class.paginates_per
        )
        # find_each raises when a LIMIT is already present; use plain each instead.
        super(@kaminari_scope, iterator: Ambassadors::Iterators::Iterator, **kwargs)
      end

      ##
      # Returns a new collection for the given page number.
      # @param number [Integer]
      # @return [PaginatedAmbassadorCollection]
      def page(number)
        self.class.new(@unscoped_enumerable, current_page: number, per_page: limit_value, **@collection_kwargs)
      end

      ##
      # Returns a new collection with the given page size.
      # @param size [Integer]
      # @return [PaginatedAmbassadorCollection]
      def per(size)
        self.class.new(@unscoped_enumerable, current_page: current_page, per_page: size, **@collection_kwargs)
      end

      ##
      # Total number of pages. Always returns at least 1, even for empty collections.
      # @return [Integer]
      def total_pages
        [@kaminari_scope.total_pages, 1].max
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

      ##
      # @param enumerable [Enumerable]
      # @param current_page [Integer]
      # @param per_page [Integer]
      # @return [ActiveRecord::Relation, Kaminari::PaginatableArray]
      def build_kaminari_scope(enumerable, current_page:, per_page:)
        scope = if defined?(ActiveRecord::Relation) && enumerable.is_a?(ActiveRecord::Relation)
          enumerable
        else
          Kaminari.paginate_array(Array(enumerable))
        end

        scope.page(current_page).per(per_page)
      end
    end
  end
end
