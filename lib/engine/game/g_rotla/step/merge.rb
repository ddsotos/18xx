# frozen_string_literal: true

require_relative '../../../step/base'

module Engine
  module Game
    module GRotLA
      module Step
        # Runs one Minor merger as a replayable offer/consent/Major-choice flow.
        # Company abilities may broaden the connection rule later; this step
        # deliberately implements only the ability-neutral rule.
        class Merge < Engine::Step::Base
          ACCEPT = 'accept'
          REJECT = 'reject'

          def round_state
            {
              pending_merger: nil,
              rejected_mergers: [],
            }
          end

          def description
            case pending_merger&.fetch(:phase, nil)
            when :consent
              'Consent to Minor Company Merger'
            when :choose_major
              'Choose Major Company'
            else
              'Merge Minor Companies'
            end
          end

          def pass_description
            'Skip Merger'
          end

          def active_entities
            return super unless pending_merger

            first, second = pending_companies
            case pending_merger[:phase]
            when :consent
              [second.owner]
            when :choose_major
              [prospective_president(first, second)]
            else
              []
            end
          end

          def actions(entity)
            return [] unless entity == current_entity

            return ['choose'] if pending_merger

            merger_partners(entity).empty? ? ['pass'] : %w[choose pass]
          end

          def choice_name
            case pending_merger&.fetch(:phase, nil)
            when :consent
              'Accept or reject merger'
            when :choose_major
              'Choose the new Major Company'
            else
              'Choose a Minor Company to merge with'
            end
          end

          def choices
            case pending_merger&.fetch(:phase, nil)
            when :consent
              consent_choices
            when :choose_major
              major_choices
            else
              merger_partner_choices(current_entity)
            end
          end

          def process_choose(action)
            case pending_merger&.fetch(:phase, nil)
            when :consent
              process_consent(action)
            when :choose_major
              process_major_choice(action)
            else
              process_offer(action)
            end
          end

          def process_pass(action)
            unless action.entity == current_entity && pending_merger.nil?
              raise GameError, 'This Minor Company cannot pass now'
            end

            @log << "#{action.entity.name} does not merge"
            pass!
          end

          private

          def pending_merger
            @round.pending_merger
          end

          def pending_companies
            [
              @game.corporation_by_id(pending_merger[:first]),
              @game.corporation_by_id(pending_merger[:second]),
            ]
          end

          def process_offer(action)
            proposer = action.entity
            partner_id = parse_prefixed_choice(action.choice, 'merge')
            partner = @game.corporation_by_id(partner_id)
            unless proposer == current_entity && merger_partners(proposer).include?(partner)
              raise GameError, 'This Minor Company merger is no longer available'
            end

            @round.pending_merger = {
              phase: :consent,
              first: proposer.id,
              second: partner.id,
            }
            @log << "#{proposer.name} proposes a merger with #{partner.name}"

            return unless proposer.owner == partner.owner

            @log << "#{partner.owner.name} automatically consents as president of both Minor Companies"
            @round.pending_merger[:phase] = :choose_major
          end

          def process_consent(action)
            first, second = validate_pending_companies!(:consent)
            unless action.entity == second.owner
              raise GameError, 'Only the partner president may answer this merger offer'
            end

            case action.choice.to_s
            when ACCEPT
              @log << "#{second.owner.name} consents to the merger of #{first.name} and #{second.name}"
              @round.pending_merger[:phase] = :choose_major
            when REJECT
              @log << "#{second.owner.name} rejects the merger of #{first.name} and #{second.name}"
              @round.rejected_mergers << merger_pair_key(first, second)
              @round.pending_merger = nil
              pass!
            else
              raise GameError, 'Invalid merger consent choice'
            end
          end

          def process_major_choice(action)
            first, second = validate_pending_companies!(:choose_major)
            president = prospective_president(first, second)
            raise GameError, 'Only the new Major president may choose the company' unless action.entity == president

            major_id = parse_prefixed_choice(action.choice, 'major')
            major = @game.corporation_by_id(major_id)
            raise GameError, 'This Major Company is no longer available' unless available_majors.include?(major)

            apply_merger!(first, second, major)
            @round.pending_merged_corporation = major if @game.num_corp_trains(major) > @game.train_limit(major)
            @round.pending_merger = nil
            pass!
          end

          def validate_pending_companies!(phase)
            unless pending_merger&.fetch(:phase, nil) == phase
              raise GameError, 'There is no pending merger at this stage'
            end

            first, second = pending_companies
            unless mergeable_minor?(first) && mergeable_minor?(second) && @game.rotla_merge_connected?(first, second)
              raise GameError, 'The pending Minor Company merger is no longer available'
            end

            [first, second]
          end

          def merger_partner_choices(proposer)
            merger_partners(proposer).to_h do |partner|
              ["merge:#{partner.id}", "Propose merger with #{partner.name}"]
            end
          end

          def consent_choices
            first, second = pending_companies
            {
              ACCEPT => "Accept merger of #{first.name} and #{second.name}",
              REJECT => "Reject merger of #{first.name} and #{second.name}",
            }
          end

          def major_choices
            available_majors.to_h { |major| ["major:#{major.id}", "Form #{major.name}"] }
          end

          def merger_partners(proposer)
            return [] unless mergeable_minor?(proposer)
            return [] if available_majors.empty?

            @game.corporations.select do |corporation|
              mergeable_minor?(corporation) &&
                corporation != proposer &&
                !@round.rejected_mergers.include?(merger_pair_key(proposer, corporation)) &&
                @game.rotla_merge_connected?(proposer, corporation)
            end
          end

          def mergeable_minor?(corporation)
            corporation&.type == :minor && corporation.floated? && !corporation.closed?
          end

          def available_majors
            @game.corporations.select do |corporation|
              corporation.type == :major && !corporation.ipoed && !corporation.closed?
            end
          end

          def merger_pair_key(first, second)
            [first.id, second.id].sort.join(':')
          end

          def parse_prefixed_choice(choice, expected_prefix)
            prefix, corporation_id, extra = choice.to_s.split(':', 3)
            unless prefix == expected_prefix && corporation_id && !corporation_id.empty? && extra.nil?
              raise GameError, 'Invalid merger choice'
            end

            corporation_id
          end

          def prospective_president(first, second)
            holdings = @game.players.to_h do |player|
              [player, (first.share_holders[player] + second.share_holders[player]) / 2]
            end
            maximum = holdings.values.max
            tied = holdings.select { |_player, percent| percent == maximum }.keys
            tied.include?(first.owner) ? first.owner : tied.first
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
            @game.rotla_transfer_abilities!([first, second], major)
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
            if plan.values.any? { |percent| (percent % 10).positive? }
              raise GameError, 'Merger share conversion is not in ten-percent units'
            end

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

                replacement = major.next_token || Engine::Token.new(major, price: 0).tap do |new_token|
                  major.tokens << new_token
                end
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
