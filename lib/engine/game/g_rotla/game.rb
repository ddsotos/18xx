# frozen_string_literal: true

require 'json'
require_relative '../base'
require_relative 'abilities'
require_relative 'entities'
require_relative 'fixed_map'
require_relative 'game_data'
require_relative 'map'
require_relative 'meta'
require_relative 'round/merger'
require_relative 'setup'
require_relative 'step/discard_merged_trains'
require_relative 'step/dividend'
require_relative 'step/issue_or_redeem'
require_relative 'step/leadoff_train'
require_relative 'step/merge'
require_relative 'stock_round'

module Engine
  module Game
    module GRotLA
      class Game < Game::Base
        include_meta(GRotLA::Meta)
        include GameData
        include Entities
        include Map
        include Abilities

        MAP_CATALOG = Map::MAP_CATALOG

        include Setup
        include FixedMap
        include StockRound

        CURRENCY_FORMAT_STR = '%s金'
        BANK_CASH = 20_000
        CERT_LIMIT = { 4 => 99 }.freeze
        COMPANIES = [].freeze
        MINORS = [].freeze
        LAYOUT = :flat
        CAPITALIZATION = :incremental
        HOME_TOKEN_TIMING = :operating_round
        MUST_BUY_TRAIN = :always
        SELL_AFTER = :operate
        SELL_MOVEMENT = :left_block
        POOL_SHARE_DROP = :none
        PRESIDENT_SALES_TO_MARKET = true
        EBUY_OWNER_MUST_HELP = true
        EBUY_DEPOT_TRAIN_MUST_BE_CHEAPEST = true
        EBUY_FROM_OTHERS = :always
        MUST_EMERGENCY_ISSUE_BEFORE_EBUY = false
        GAME_END_CHECK = { bankrupt: :immediate }.freeze
        TILE_LAYS = [{ lay: true, upgrade: true, cost: 0 }, { lay: true, upgrade: false, cost: 0 }].freeze
        TRACK_UPGRADE_COLORS = %i[yellow green purple gray].freeze

        def initialize(names, settings: nil, **kwargs)
          settings = JSON.parse(JSON.generate(settings || {}))
          settings['rotla'] ||= JSON.parse(JSON.generate(Map::DEFAULT_SETTINGS.fetch('rotla')))
          super(names, settings: settings, **kwargs)
        end

        def init_round
          stock_round
        end

        def init_corporations(stock_market)
          corporations = super
          home_coordinates = @rotla_map_builder.company_home_coordinates
          fixed_home_minors = corporations.select do |corporation|
            corporation.type == :minor && corporation.id != Entities::ADAPTIVE_ID
          end
          unless home_coordinates.size == fixed_home_minors.size
            raise GameError, 'The finalized RotLA map must provide one home for each non-Adaptive Minor Company'
          end

          fixed_home_minors.zip(home_coordinates) do |corporation, coordinate|
            corporation.coordinates = coordinate
          end
          corporations
        end

        def operating_round(round_num)
          Engine::Round::Operating.new(self, [
            Engine::Step::Bankrupt,
            Engine::Step::HomeToken,
            Step::LeadoffTrain,
            Step::IssueOrRedeem,
            Engine::Step::Track,
            Engine::Step::Token,
            Engine::Step::Route,
            Step::Dividend,
            Engine::Step::DiscardTrain,
            Engine::Step::BuyTrain,
          ], round_num: round_num)
        end

        def merger_round
          Round::Merger.new(self, [Step::Merge, Step::DiscardMergedTrains])
        end

        def train_limit(entity)
          super + (rotla_has_ability?(entity, :spacious) ? 1 : 0)
        end

        def check_distance(route, visits, train = nil)
          train ||= route.train
          visits = rotla_overnight_stops(route.corporation, visits)
          return super(route, visits, train) unless rotla_express_active?(route.corporation, train)
          return super(route, visits, train) unless train.distance.is_a?(Numeric)

          express_train = train.dup
          express_train.distance = train.distance + 1
          super(route, visits, express_train)
        end

        def check_connected(route, corporation)
          return super unless rotla_has_ability?(corporation, :overnight)
          return if route.ordered_paths.each_cons(2).all? { |first, second| first.connects_to?(second, nil) }

          raise GameError, 'Route is not connected'
        end

        def check_other(route)
          super
          return unless rotla_has_ability?(route.corporation, :overnight)

          paying_stops = rotla_overnight_stops(route.corporation, route.visited_stops)
          if !route.connection_data.empty? && paying_stops.size < 2 && !route.train.local?
            raise RouteTooShort, 'Overnight route must have at least 2 non-blocked stops'
          end

          pass_through_visits = route.connection_data
            .flat_map { |connection| [connection[:left], connection[:right]] }
            .compact
            .select { |stop| rotla_overnight_pass_through?(route.corporation, stop) }
          return unless pass_through_visits.tally.values.any? { |count| count > 2 }

          raise GameError, 'Overnight route cannot visit the same blocked city more than once'
        end

        def revenue_stops(route)
          rotla_overnight_stops(route.corporation, super)
        end

        def route_distance(route)
          rotla_overnight_stops(route.corporation, route.visited_stops).sum(&:visit_cost)
        end

        def graph_for_entity(entity)
          return rotla_overnight_graph if rotla_has_ability?(entity, :overnight)

          super
        end

        def token_graph_for_entity(entity)
          return rotla_overnight_graph if rotla_has_ability?(entity, :overnight)

          super
        end

        def clear_graph
          super
          @rotla_overnight_graph&.clear
        end

        # Merger connectivity is independent of train distance. The normal graph
        # still enforces token blocking, so a partner hub must be reachable by an
        # unblocked continuous route from one of the proposer's hubs.
        def rotla_merge_connected?(first, second)
          partner_cities = second.tokens.select(&:used).filter_map(&:city)
          return false if partner_cities.empty?

          graph = if rotla_has_ability?(first, :overnight) || rotla_has_ability?(second, :overnight)
                    rotla_overnight_graph
                  else
                    graph_for_entity(first)
                  end
          connected_nodes = graph.connected_nodes(first)
          partner_cities.any? { |city| connected_nodes.key?(city) }
        end

        def next_round!
          @round = case @round
                   when GRotLA::Round::Stock
                     @operating_rounds = 2
                     reorder_players
                     new_operating_round
                   when Engine::Round::Operating
                     if @round.round_num < @operating_rounds
                       or_round_finished
                       new_operating_round(@round.round_num + 1)
                     else
                       or_round_finished
                       or_set_finished
                       @phase.tiles.include?(:green) ? merger_round : finish_cycle!
                     end
                   when GRotLA::Round::Merger
                     finish_cycle!
                   end
        end

        def finish_cycle!
          if @turn >= 6
            end_game!(:fixed_round)
            @round
          else
            export_train!
            @turn += 1
            new_stock_round
          end
        end

        def export_train!
          @depot.export! unless @depot.empty?
        end

        def operating_order
          @corporations.select(&:floated?).sort
        end

        def rotla_corporation_operated?(corporation)
          corporation.operated?
        end

        def upgrades_to_correct_color?(from, to, selected_company: nil)
          return false if from.color == :blue || to.color == :blue

          from_index = TRACK_UPGRADE_COLORS.index(from.color)
          return super(from, to, selected_company: selected_company) unless from_index

          to.color == TRACK_UPGRADE_COLORS[from_index + 1]
        end

        def issuable_shares(entity)
          return [] unless entity.corporation?

          bundles_for_corporation(entity, entity).select do |bundle|
            bundle.shares.one? && !bundle.presidents_share && !bundle.partial? &&
              bundle.percent == entity.share_percent && @share_pool.fit_in_bank?(bundle)
          end
        end

        def redeemable_shares(entity)
          return [] unless entity.corporation?

          bundles_for_corporation(@share_pool, entity).select do |bundle|
            bundle.shares.one? && !bundle.presidents_share && !bundle.partial? &&
              bundle.percent == entity.share_percent && entity.cash >= bundle.price
          end
        end

        def status_array(corporation)
          status = Array(super)
          abilities = rotla_ability_ids(corporation).map do |ability_id|
            name = rotla_ability_name(ability_id)
            rotla_ability_implemented?(ability_id) ? name : "#{name} (pending)"
          end
          status << "Abilities: #{abilities.join(', ')}" unless abilities.empty?
          status
        end

        private

        def rotla_express_active?(corporation, train)
          rotla_has_ability?(corporation, :express) &&
            corporation.trains.one? &&
            corporation.trains.first == train
        end

        def rotla_overnight_stops(corporation, stops)
          return stops unless rotla_has_ability?(corporation, :overnight)

          stops.reject { |stop| rotla_overnight_pass_through?(corporation, stop) }
        end

        def rotla_overnight_pass_through?(corporation, stop)
          stop.city? && stop.blocks?(corporation)
        end

        def rotla_overnight_graph
          @rotla_overnight_graph ||= Engine::Graph.new(self, no_blocking: true)
        end
      end
    end
  end
end
