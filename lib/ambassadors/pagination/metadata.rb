# frozen_string_literal: true

module Ambassadors
  module Pagination
    ##
    # Pagination metadata for a {PaginatedAmbassadorCollection}.
    # A read-only value object exposing page state for JSON serialisation and
    # programmatic inspection.
    #
    # @example
    #   meta = collection.metadata
    #   meta.current_page  #=> 2
    #   meta.total_pages   #=> 10
    #   meta.to_h          #=> { current_page: 2, per_page: 25, ... }
    class Metadata
      ##
      # @return [Integer] the current page number (1-based)
      attr_reader :current_page

      ##
      # @return [Integer] number of records per page
      attr_reader :per_page

      ##
      # @return [Integer] total number of records across all pages
      attr_reader :total_count

      ##
      # @return [Integer] total number of pages
      attr_reader :total_pages

      ##
      # @param current_page [Integer]
      # @param per_page [Integer]
      # @param total_count [Integer]
      # @param total_pages [Integer]
      def initialize(current_page:, per_page:, total_count:, total_pages:)
        @current_page = current_page
        @per_page = per_page
        @total_count = total_count
        @total_pages = total_pages
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
      # @return [Boolean] true when the current page is beyond the last page
      def out_of_range?
        current_page > total_pages
      end

      ##
      # @return [Hash] all metadata as a plain hash suitable for JSON serialisation
      def to_h
        {
          current_page: current_page,
          per_page: per_page,
          total_count: total_count,
          total_pages: total_pages,
          next_page: next_page,
          prev_page: prev_page,
          first_page: first_page?,
          last_page: last_page?,
          out_of_range: out_of_range?
        }
      end
    end
  end
end
