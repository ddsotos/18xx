# frozen_string_literal: true

require 'json'
require_relative '../base'
require_relative 'entities'
require_relative 'fixed_map'
require_relative 'game_data'
require_relative 'map'
require_relative 'meta'
require_relative 'round/merger'
require_relative 'setup'
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

        def initialize(names, settings: nil, **kwargs)
          settings = JSON.parse(JSON.generate(settings || {}))
          settings['rotla'] ||= JSON.parse(JSON.generate(Map::DEFAULT_SETTINGS.fetch('rotla')))
          super(names, settings: settings, **kwargs)
        end

        def init_round
          stock_round
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
          Round::Merger.new(self, [Step::Merge])
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

        def tile_lays(_entity)
          []
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
          ability = Entities::ABILITY_BY_MINOR[corporation.id]
          status << "Ability pending: #{ability}" if ability
          status
        end
      end
    end
  end
end
