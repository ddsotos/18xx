# frozen_string_literal: true

require_relative '../../../step/base'

module Engine
  module Game
    module GRotLA
      module Step
        # Ability-neutral merger core for the playable alpha. A single stable
        # Choose value identifies both the partner and unused Major.
        class Merge < Engine::Step::Base
          def description
            'Merge Minor Companies'
          end

          def pass_description
            'Skip Merger'
          end

          def actions(entity)
            return [] unless entity == current_entity

            merger_choices(entity).empty? ? ['pass'] : %w[choose pass]
          end

          def choices
            merger_choices(current_entity).to_h do |partner, major|
              key = choice_key(partner, major)
              [key, "Merge with #{partner.name} as #{major.name}"]
            end
          end

          def process_choose(action)
            proposer = action.entity
            partner_id, major_id = parse_choice(action.choice)
            partner = @game.corporation_by_id(partner_id)
            major = @game.corporation_by_id(major_id)
            unless merger_choices(proposer).include?([partner, major])
              raise GameError, 'This Minor Company merger is no longer available'
            end

            apply_merger!(proposer, partner, major)
            pass!
          end

          def process_pass(action)
            @log << "#{action.entity.name} does not merge"
            pass!
          end

          private

          def merger_choices(proposer)
            return [] unless proposer&.type == :minor && proposer.floated? && !proposer.closed?

            partners = @game.corporations.select do |corporation|
              corporation != proposer && corporation.type == :minor && corporation.floated? && !corporation.closed?
            end
            majors = @game.corporations.select do |corporation|
              corporation.type == :major && !corporation.ipoed && !corporation.closed?
            end
            partners.product(majors)
          end

          def choice_key(partner, major)
            "merge:#{partner.id}:#{major.id}"
          end

          def parse_choice(choice)
            prefix, partner_id, major_id = choice.to_s.split(':', 3)
            raise GameError, 'Invalid merger choice' unless prefix == 'merge' && partner_id && major_id

            [partner_id, major_id]
          end

          def apply_merger!(first, second, major)
            share_plan = share_plan(first, second, major)
            president = merger_president(first, share_plan)
            share_price = merger_share_price(first, second)
            raise GameError, 'No legal Major share price exists for this merger' unless share_price

            @game.stock_market.set_par(major, share_price)
            major.ipoed = true
            major.floated = true
            transfer_major_shares!(major, president, share_plan)
            transfer_assets!(first, major)
            transfer_assets!(second, major)
            transfer_tokens!(first, second, major)
            close_minor!(first)
            close_minor!(second)
            @game.clear_graph

            @log << "#{first.name} and #{second.name} merge as #{major.name} at " \
                    "#{@game.format_currency(share_price.price)}; #{president.name} is president"
          end

          def share_plan(first, second, major)
            holders = (first.share_holders.keys + second.share_holders.keys).uniq
            plan = Hash.new(0)
            holders.each do |holder|
              percent = (first.share_holders[holder] + second.share_holders[holder]) / 2
              target = holder == first || holder == second ? major : holder
              plan[target] += percent
            end
            plan[major] = plan.fetch(major, 0) + (100 - plan.values.sum)
            raise GameError, 'Merger share conversion is not in ten-percent units' if plan.values.any? { |p| (p % 10).positive? }

            plan
          end

          def merger_president(first, plan)
            players = @game.players.select { |player| plan.fetch(player, 0).positive? }
            maximum = players.map { |player| plan.fetch(player) }.max
            tied = players.select { |player| plan.fetch(player) == maximum }
            tied.include?(first.owner) ? first.owner : tied.first
          end

          def merger_share_price(first, second)
            average = (first.share_price.price + second.share_price.price) / 2
            @game.stock_market.par_prices.select { |price| price.price <= average }.max_by(&:price)
          end

          def transfer_major_shares!(major, president, plan)
            president_share = major.presidents_share
            @game.share_pool.transfer_shares(president_share.to_bundle, president)
            remaining = plan.dup
            remaining[president] -= president_share.percent

            remaining.each do |holder, percent|
              next if holder == major || percent.zero?

              (percent / major.share_percent).times do
                share = major.treasury_shares.find { |candidate| !candidate.president }
                raise GameError, 'Major does not have enough ordinary shares for merger conversion' unless share

                @game.share_pool.transfer_shares(share.to_bundle, holder)
              end
            end
          end

          def transfer_assets!(minor, major)
            minor.spend(minor.cash, major) if minor.cash.positive?
            minor.trains.dup.each { |train| @game.buy_train(major, train, :free) }
          end

          def transfer_tokens!(first, second, major)
            used_cities = {}
            [first, second].each do |minor|
              minor.tokens.select(&:used).each do |token|
                city = token.city
                if used_cities[city]
                  token.remove!
                  next
                end

                replacement = major.next_token || Engine::Token.new(major, price: 0).tap { |new_token| major.tokens << new_token }
                token.swap!(replacement, check_tokenable: false)
                used_cities[city] = true
              end
            end
          end

          def close_minor!(minor)
            minor.share_price&.corporations&.delete(minor)
            minor.floated = false
            minor.close!
          end
        end
      end
    end
  end
end
