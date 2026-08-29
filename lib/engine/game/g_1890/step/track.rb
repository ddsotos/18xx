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
              @game.finish_osaka_metro_special_tile_lay!
              pass! unless can_lay_tile?(action.entity)
            else
              super
            end
            @game.refresh_kobe_rapid_blocking!
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

          def hex_neighbors(entity, hex)
            return hex.neighbors.keys if @game.osaka_metro_special_tile_lay?(entity, hex)

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
                return [] unless @game.phase.tiles.include?(:brown)

                return special_upgradeable_tiles(entity, hex, 'BNI')
              when 'I12'
                return [] unless @game.phase.tiles.include?(:brown) && hex.tile.name == '12'

                return special_upgradeable_tiles(entity, hex, 'BOW')
              end
            end
            tiles = super
            tiles.reject { |t| %w[BNI BOW].include?(t.name) }
          end

          def special_upgradeable_tiles(entity, hex, tile_name)
            tile = @game.tiles.find { |candidate| candidate.name == tile_name }
            return [] unless tile

            tile.rotate!(0)
            tile.legal_rotations = legal_tile_rotations(entity, hex, tile)
            return [] if tile.legal_rotations.empty?

            tile.rotate!
            [tile]
          end

        end
      end
    end
  end
end
