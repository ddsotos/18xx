# frozen_string_literal: true

require_relative '../../../step/track'

module Engine
  module Game
    module G1890
      module Step
        class Track < Engine::Step::Track
          def process_lay_tile(action)
            osaka_metro_special_tile_lay = @game.osaka_metro_special_tile_lay?(action.entity) &&
              @game.osaka_metro_special_tile_lay?(action.entity, action.hex)
            if osaka_metro_special_tile_lay
              lay_tile_action(action)
              @round.num_laid_track -= 1
              @game.finish_osaka_metro_special_tile_lay!
              pass! unless can_lay_tile?(action.entity)
            else
              super
            end
            @game.clear_graph_for_entity(action.entity)
            return unless action.entity.id == '阪急' && action.tile.color == :yellow

            @game.bank.spend(10, action.entity)
            @log << "#{action.entity.name} receives #{@game.format_currency(10)} for laying a yellow tile"
          end

          def process_pass(action)
            @game.finish_osaka_metro_special_tile_lay! if @game.osaka_metro_special_tile_lay?(action.entity)

            super
          end

          def available_hex(entity, hex)
            if @game.osaka_metro_special_tile_lay?(entity)
              return nil unless @game.osaka_metro_special_tile_lay?(entity, hex)

              return hex.neighbors.keys
            end

            super
          end

          def legal_tile_rotation?(entity_or_entities, hex, tile)
            entity = Array(entity_or_entities).first
            return true if @game.osaka_metro_special_tile_lay?(entity, hex)

            super
          end

          def check_track_restrictions!(entity, old_tile, new_tile)
            return if @game.osaka_metro_special_tile_lay?(entity, old_tile.hex)

            super
          end

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
              case hex.id
              when 'F9'
                return @game.tiles.select { |t| t.name == 'BNI' }
              when 'H11'
                return @game.tiles.select { |t| t.name == 'BOS' }
              end
            end
            tiles = super
            tiles.reject { |t| %w[BNI BOS].include?(t.name) }
          end


        end
      end
    end
  end
end
