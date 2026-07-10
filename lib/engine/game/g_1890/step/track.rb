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


          def upgradeable_tiles(entity, hex)
            if hex.tile.color == :green
              case hex.location_name
              when "西宮"
                return @game.tiles.select { |t| t.name == 'BNI' }
              when "大阪西"
                return @game.tiles.select { |t| t.name == 'BOS' }
              end
            end
            tiles = super
            return tiles.reject { |t| t.name == 'BNI'}
          end


        end
      end
    end
  end
end
