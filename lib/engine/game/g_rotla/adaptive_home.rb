# frozen_string_literal: true

module Engine
  module Game
    module GRotLA
      # Validation shared by the founding and home-selection steps.
      #
      # The map owns the definition of a basic city: in particular, it must
      # omit capitals and cities belonging to special companies. The step
      # applies the dynamic checks (reservations, tokens, and available slots)
      # to the returned Engine::Part::City objects. The game supplies the
      # rotla_adaptive_home_cities(corporation) hook documented below.
      module AdaptiveHome
        module_function

        def home_token(corporation)
          token = corporation.tokens.first
          token unless token&.used
        end

        def candidate_cities(game, corporation)
          unless game.respond_to?(:rotla_adaptive_home_cities)
            raise GameError, 'RotLA game must define rotla_adaptive_home_cities(corporation)'
          end

          cities = game.rotla_adaptive_home_cities(corporation)
          valid_cities = cities.is_a?(Array) && cities.all? { |city| city.is_a?(Engine::Part::City) }
          raise GameError, 'rotla_adaptive_home_cities must return Engine::Part::City objects' unless valid_cities

          ids = cities.map(&:id)
          valid_ids = ids.all? { |id| id.is_a?(String) && !id.empty? }
          raise GameError, 'rotla_adaptive_home_cities must return cities with stable string IDs' unless valid_ids
          raise GameError, 'rotla_adaptive_home_cities returned duplicate city IDs' unless ids.uniq.size == ids.size

          on_map = cities.all? { |city| game.city_by_id(city.id).equal?(city) }
          raise GameError, 'rotla_adaptive_home_cities must return cities on the current map' unless on_map

          cities
        end

        def legal_cities(game, corporation)
          token = home_token(corporation)
          return [] unless token

          candidate_cities(game, corporation).select do |city|
            city.tokens.compact.empty? &&
              city.extra_tokens.empty? &&
              Array(city.reservations).compact.empty? &&
              Array(city.tile.reservations).compact.empty? &&
              city.tokenable?(corporation, free: true, tokens: token)
          end
        end
      end
    end
  end
end
