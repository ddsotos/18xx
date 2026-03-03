# frozen_string_literal: true

require_relative '../../../step/track'

module Engine
  module Game
    module G1890
      module Step
        class Track < Engine::Step::Track
          def can_lay_tile?(entity)
            return true if tile_lay_abilities_should_block?(entity)
            return true if can_buy_tile_laying_company?(entity, time: type)

            action = get_tile_lay(entity)
            return false unless action

            # !entity.tokens.empty? && Trackerのこの部分を除かないと、阪鉄は駅がないのでおかしくなる
            (buying_power(entity) >= action[:cost]) && (action[:lay] || action[:upgrade])
          end

        end
      end
    end
  end
end
