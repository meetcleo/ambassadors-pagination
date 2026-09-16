# frozen_string_literal: true

require "forwardable"

# Load only Kaminari's core - the view and ActiveRecord integrations are not
# required here since this gem extends a collection, not an AR scope.
require "kaminari/core"

require "ambassadors"

require_relative "pagination/version"
require_relative "pagination/metadata"
require_relative "pagination/paginated_ambassador_collection"

module Ambassadors
  ##
  # Kaminari-backed pagination for {::AmbassadorCollection}.
  #
  # Pagination is opt-in. The page window is applied to the underlying
  # enumerable before records are loaded, so the memory protection that
  # {::AmbassadorCollection} provides via batch iteration is preserved:
  # at most +per_page+ records are ever materialised at once.
  module Pagination
  end
end
