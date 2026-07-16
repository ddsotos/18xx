# frozen_string_literal: true

require_relative '../../../step/train'

module Engine
  module Game
    module G1890
      module Step
        class BuyTrain < Engine::Step::BuyTrain
          def can_entity_buy_train?(_entity = nil)
            true
          end

        end
      end
    end
  end
end
