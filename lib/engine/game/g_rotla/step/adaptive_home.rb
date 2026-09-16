# frozen_string_literal: true

require_relative '../../../step/base'
require_relative '../adaptive_home'
require_relative '../entities'

module Engine
  module Game
    module GRotLA
      module Step
        # Resolves the home city choice left by FoundingAuction for Adaptive.
        #
        # The map-specific game hook returns basic Engine::Part::City objects;
        # this step deliberately does not contain map coordinates or guessed
        # city IDs. Choices are serialized using City#id, the engine-standard
        # tile ID and tile-part index (for example, "X7-0-0").
        class AdaptiveHome < Engine::Step::Base
          ACTIONS = %w[choose].freeze

          def description
            'Choose Adaptive Home'
          end

          def blocks?
            !pending_adaptive_home.nil?
          end

          # Keep the stock round blocked even if a malformed save has no
          # owner or no legal candidate. Such a state must be repaired by a
          # valid Choose action or surfaced as a game error, not skipped.
          def blocking?
            blocks?
          end

          def active_entities
            return [] unless (corporation = pending_adaptive_home)

            [corporation.owner].compact
          end

          def current_entity
            active_entities.first
          end

          def actions(entity)
            return [] unless entity == current_entity

            ACTIONS
          end

          def choices
            legal_cities.to_h do |city|
              [city.id, city_name(city)]
            end
          end

          def pending_adaptive_home
            @round.pending_adaptive_home
          end

          def process_choose(action)
            corporation = pending_adaptive_home
            validate_actor!(action.entity, corporation)

            city = city_for_choice(action.choice)
            raise GameError, 'Chosen Adaptive home city is not legal' unless city

            token = GRotLA::AdaptiveHome.home_token(corporation)
            raise GameError, 'Adaptive has no unused home token' unless token

            # City#place_token performs the real token bookkeeping, including
            # token.city/token.hex and removal of any matching reservation.
            city.place_token(corporation, token, free: true)
            corporation.coordinates = city.hex.id
            @game.clear_graph_for_entity(corporation) if @game.respond_to?(:clear_graph_for_entity)
            @round.pending_adaptive_home = nil
            @log << "#{corporation.name} places its home token on #{city_name(city)}"
          end

          private

          def legal_cities
            return [] unless pending_adaptive_home

            GRotLA::AdaptiveHome.legal_cities(@game, pending_adaptive_home)
          end

          def city_for_choice(choice)
            return unless choice.is_a?(String)

            # Match the engine's action deserialization contract first, then
            # require that the resolved city is in the currently legal set.
            resolved = @game.city_by_id(choice)

            legal_cities.find { |city| city.equal?(resolved) }
          end

          def city_name(city)
            city.hex&.location_name || city.id
          end

          def validate_actor!(actor, corporation)
            raise GameError, 'No Adaptive home is waiting for a choice' unless corporation

            valid_adaptive = corporation.id == Entities::ADAPTIVE_ID && corporation.type&.to_sym == :minor
            raise GameError, 'Pending home company is not Adaptive' unless valid_adaptive
            raise GameError, 'Adaptive has no unused home token' unless GRotLA::AdaptiveHome.home_token(corporation)
            raise GameError, 'Only the Adaptive president may choose its home' unless actor == corporation.owner
          end
        end
      end
    end
  end
end
