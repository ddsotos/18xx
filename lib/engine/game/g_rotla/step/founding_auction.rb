# frozen_string_literal: true

require_relative '../../../step/base'
require_relative '../adaptive_home'
require_relative '../entities'
require_relative '../founding_auction_state'
require_relative '../minor_tableau'

module Engine
  module Game
    module GRotLA
      module Step
        # Auctions the right to choose one currently visible Minor Company.
        # It is non-blocking before the first bid, so a later stock-trading
        # step can offer its actions on the same normal stock turn.
        class FoundingAuction < Engine::Step::Base
          attr_reader :auction_state, :minor_tableau

          def setup
            @minor_tableau = @game.rotla_minor_tableau
            return if @minor_tableau.is_a?(MinorTableau)

            raise GameError, 'RotLA game must own a persistent MinorTableau'
          end

          def description
            company_choice? ? 'Choose Minor Company' : 'Found Minor Company'
          end

          def pass_description
            'Pass (Auction)'
          end

          def blocks?
            !@auction_state.nil?
          end

          def active_entities
            return super unless @auction_state

            [player_by_id(@auction_state.current_bidder_id)].compact
          end

          def actions(entity)
            return [] unless entity == current_entity

            if company_choice?
              ['choose']
            elsif @auction_state
              actions = ['pass']
              actions.unshift('bid') if entity.cash >= @auction_state.high_bid + FoundingAuctionState::BID_INCREMENT
              actions
            elsif !@minor_tableau.empty? && entity.cash >= FoundingAuctionState::MIN_BID
              ['bid']
            else
              []
            end
          end

          def choices
            @minor_tableau.front_ids.to_h do |company_id|
              corporation = corporation_by_id(company_id)
              [company_id, corporation&.full_name || company_id]
            end
          end

          def pending_adaptive_home
            @round.pending_adaptive_home
          end

          def round_state
            { pending_adaptive_home: nil }
          end

          def process_bid(action)
            reject_targeted_bid!(action)
            validate_cash!(action.entity, action.price)

            if @auction_state
              apply_state { @auction_state.bid!(action.entity.id, action.price) }
            else
              apply_state do
                @auction_state = FoundingAuctionState.new(
                  player_ids: entities.map(&:id),
                  initiator_id: action.entity.id,
                  price: action.price,
                )
              end
            end
            @log << "#{action.entity.name} bids #{format_currency(action.price)} to found a Minor Company"
          end

          def process_pass(action)
            raise GameError, 'No founding auction is in progress' unless @auction_state

            apply_state { @auction_state.pass!(action.entity.id) }
            @log << "#{action.entity.name} passes the founding auction"
          end

          def process_choose(action)
            winner = action.entity
            company_id = action.choice
            corporation = corporation_by_id(company_id)
            share_price = settlement_share_price
            validate_settlement!(winner, corporation, company_id, share_price)

            resume_player_id = @auction_state.resume_player_id
            apply_state { @auction_state.validate_company_choice!(winner.id, company_id, tableau: @minor_tableau) }

            # All validation is complete before these mutations. Passing the
            # auction price directly keeps the full winning bid in treasury.
            @game.stock_market.set_par(corporation, share_price)
            @game.share_pool.transfer_shares(
              corporation.presidents_share.to_bundle,
              winner,
              spender: winner,
              receiver: corporation,
              price: @auction_state.high_bid,
            )
            corporation.ipoed = true
            corporation.floated = true
            apply_state { @auction_state.choose_company!(winner.id, company_id, tableau: @minor_tableau) }

            @round.pending_adaptive_home = corporation if company_id == Entities::ADAPTIVE_ID
            @log << "#{winner.name} founds #{corporation.full_name} for #{format_currency(@auction_state.high_bid)} " \
                    "at #{format_currency(share_price.price)}"
            @auction_state = nil
            @round.goto_entity!(player_by_id(resume_player_id))
          end

          private

          def company_choice?
            @auction_state&.phase == :company_choice
          end

          def entities
            @round.entities
          end

          def player_by_id(id)
            entities.find { |player| player.id == id }
          end

          def corporation_by_id(id)
            @game.corporation_by_id(id)
          end

          def reject_targeted_bid!(action)
            targeted = action.company || action.corporation || action.minor
            return unless targeted

            raise GameError, 'A founding bid is for the right to choose a company later'
          end

          def validate_cash!(player, price)
            raise GameError, 'Bid must be an integer' unless price.is_a?(Integer)
            raise GameError, "#{player.name} cannot afford #{format_currency(price)}" if price > player.cash
          end

          def settlement_share_price
            return unless @auction_state

            half_bid = @auction_state.high_bid / 2
            maximum = phase_par_maximum
            @game.stock_market.par_prices
              .select { |price| price.price.between?(60, maximum) && price.price <= half_bid }
              .max_by(&:price)
          end

          def phase_par_maximum
            colors = @game.phase.tiles
            return 135 if (colors & %i[purple gray]).any?
            return 110 if colors.include?(:green)

            90
          end

          def validate_settlement!(winner, corporation, company_id, share_price)
            raise GameError, 'Auction is not waiting for a company choice' unless company_choice?
            raise GameError, 'Only the auction winner may choose' unless winner.id == @auction_state.winner_id
            raise GameError, 'Chosen Minor Company is not available' unless @minor_tableau.front?(company_id)
            raise GameError, "Unknown Minor Company #{company_id}" unless corporation
            raise GameError, 'Chosen company is not a Minor Company' unless corporation.type == :minor
            raise GameError, 'Chosen company has already been founded' if corporation.share_price || corporation.ipoed

            valid_president_share = corporation.presidents_share.percent == 40 &&
                                    corporation.presidents_share.owner == corporation
            raise GameError, 'Chosen company does not have its unowned 40% president share' unless valid_president_share
            raise GameError, 'No phase-allowed share price exists for the winning bid' unless share_price

            if company_id == Entities::ADAPTIVE_ID && GRotLA::AdaptiveHome.legal_cities(@game, corporation).empty?
              raise GameError, 'Adaptive has no legal home city'
            end

            validate_cash!(winner, @auction_state.high_bid)
          end

          def apply_state
            yield
          rescue ArgumentError => e
            raise GameError, e.message
          end

          def format_currency(amount)
            @game.format_currency(amount)
          end
        end
      end
    end
  end
end
