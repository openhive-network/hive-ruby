module Hive
  # {Bridge} is used to query values related to the communities.
  #
  # Also see: {https://developers.hive.io/apidefinitions/bridge.html Bridge Definitions}
  class Bridge < Api
    def initialize(options = {})
      self.class.api_name = :bridge
      
      super
    end
  end
end
