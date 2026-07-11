# frozen_string_literal: true

require_relative '../../../step/waterfall_auction'

module Engine
  module Game
    module G1890
      module Step
        class WaterfallAuction < Engine::Step::WaterfallAuction
          def setup
            super
            @companies = @game.initial_auction_companies.dup
            @cheapest = @companies.first
          end
        end
      end
    end
  end
end
