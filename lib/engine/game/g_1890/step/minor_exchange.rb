# frozen_string_literal: true

require_relative '../../../step/share_buying'

module Engine
  module Game
    module G1890
      module MinorExchange
        include Engine::Step::ShareBuying

        def connected_corporations(minor)
          ability = @game.abilities(minor, :exchange)
          @game.exchange_corporations(ability)
        end

        def exchange?(corporation)
          corporation.available_share || @game.share_pool.shares_by_corporation[corporation]&.first
        end



        def exchange_share(minor, corporation, source)
          return unless corporation

          @game.log << "#{minor.owner.name} exchanges #{minor.name} for a "\
                       "10% share of #{corporation.name}"

          bundle = if source == corporation
                     corporation.treasury_shares.first.to_bundle
                   else
                     @game.share_pool.shares_of(corporation).first.to_bundle
                   end

          buy_shares(minor.owner, bundle, exchange: true)
        end

        def transfer_treasury(source, destination)
          return unless source.cash.positive?

          @game.log << "#{destination.name} takes #{@game.format_currency(source.cash)}"\
                       " from #{source.name} remaining cash"

          source.spend(source.cash, destination)
        end


        def can_gain?(entity, bundle, exchange: false)
          return if !bundle || !entity
          return true if exchange

          super
        end
      end
    end
  end
end
