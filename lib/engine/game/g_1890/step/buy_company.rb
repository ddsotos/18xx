# frozen_string_literal: true

require_relative '../../../step/buy_company'

module Engine
  module Game
    module G1890
      module Step
        class BuyCompany < Engine::Step::BuyCompany
          def skip!
            return pass! if current_entity&.minor?

            super
          end
        end
      end
    end
  end
end
