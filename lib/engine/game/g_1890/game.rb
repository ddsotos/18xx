# frozen_string_literal: true

require_relative 'entities'
require_relative 'map'
require_relative 'meta'
require_relative 'step/special_track'
require_relative '../base'

module Engine
  module Game
    module G1890
      class Game < Game::Base
        include_meta(G1890::Meta)
        include Entities
        include Map

        register_colors(black: '#37383a',
                        orange: '#f48221',
                        brightGreen: '#76a042',
                        red: '#d81e3e',
                        turquoise: '#00a993',
                        blue: '#0189d1',
                        brown: '#7b352a')

        CURRENCY_FORMAT_STR = '¥%s'

        BANK_CASH = 7000

        CERT_LIMIT = { 2 => 25, 3 => 19, 4 => 14, 5 => 12, 6 => 11 }.freeze

        STARTING_CASH = { 2 => 420, 3 => 420, 4 => 420, 5 => 390, 6 => 390 }.freeze

        CAPITALIZATION = :full

        MUST_SELL_IN_BLOCKS = true

        MARKET = [
          %w[75 80 90 100p 110 125 140 155 175 200 225 255 285 315 350],
          %w[70 75 80 90p 100 110 125 140 155 175 200 225 255 285 315],
          %w[65 70 75 80p 90 100 110 125 140 155 175 200],
          %w[60 65 70 75p 80 90 100 110 125 140],
          %w[55 60 65 70p 75 80 90 100],
          %w[50y 55 60 65p 70 75 80],
          %w[45y 50y 55 60 65 70],
          %w[40y 45y 50y 55 60],
          %w[30o 40y 45y 50y],
          %w[20o 30o 40y 45y],
          %w[10o 20o 30o 40y],
        ].freeze

        PHASES = [
          {
            name: '2',
            train_limit: 4,
            tiles: [:yellow],
            operating_rounds: 1,
          },
          {
            name: '3',
            on: '3',
            train_limit: 4,
            tiles: %i[yellow green],
            operating_rounds: 2,
            status: ['can_buy_companies'],
          },
          {
            name: '4',
            on: '4',
            train_limit: 3,
            tiles: %i[yellow green],
            operating_rounds: 2,
            status: ['can_buy_companies'],
          },
          {
            name: '5',
            on: '5',
            train_limit: 2,
            tiles: %i[yellow green brown],
            operating_rounds: 3,
          },
          {
            name: '6',
            on: '6',
            train_limit: 2,
            tiles: %i[yellow green brown],
            operating_rounds: 3,
          },
          {
            name: 'D',
            on: 'D',
            train_limit: 2,
            tiles: %i[yellow green brown],
            operating_rounds: 3,
          },
        ].freeze

        TRAINS = [
          {
            name: '2',
            distance: 2,
            price: 80,
            rusts_on: '4',
            num: 6,
          },
          {
            name: '3',
            distance: 3,
            price: 180,
            rusts_on: '6',
            num: 5,
          },
          {
            name: '4',
            distance: 4,
            price: 300,
            rusts_on: 'D',
            num: 4,
          },
          {
            name: '5',
            distance: 5,
            price: 450,
            num: 3,
            events: [{ 'type' => 'close_companies' }],
          },
          { name: '6', distance: 6, price: 630, num: 2 },
          {
            name: 'D',
            distance: 999,
            price: 1100,
            num: 'unlimited',
            available_on: '6',
            discount: { '4' => 300, '5' => 300, '6' => 300 },
          },
].freeze

        EBUY_PRES_SWAP = false # allow presidential swaps of other corps when ebuying
        EBUY_FROM_OTHERS = :never # allow ebuying other corp trains for up to face
        HOME_TOKEN_TIMING = :operating_round



        def setup_preround
          @companies, @latecomer_companies = @companies.partition do 
            |c| c.type != :latecomer
          end
          @companies.each { |c| @log << "is #{c.type} " }
          @latecomer_companies.each { |c| c.owner = @bank}
        end

        def setup
          super
          @minors.each {|m| place_home_token(m)}
        end


        def operating_round(round_num)
          G1890::Round::Operating.new(self, [
            Engine::Step::Bankrupt,
            G1890::Step::Exchange,
            G1890::Step::SpecialTrack,
            Engine::Step::BuyCompany,
            G1890::Step::Track,
            Engine::Step::Token,
            Engine::Step::Route,
            Engine::Step::Dividend,
            Engine::Step::DiscardTrain,
            G1890::Step::BuyTrain,
            [Engine::Step::BuyCompany, { blocks: true }],
          ], round_num: round_num)
        end

        def active_players
          return super if @finished

          company = company_by_id('ER')
          current_entity == company ? [@round.company_sellers[company]] : super
        end

        def bank_first?
          false
        end

        def new_stock_round
          @log << "new stock round. old round is #{@turn} "

          case @turn
          when 1
            @corporations.each{
            |c| if c.name == '近鉄'
                shares =c.ipo_shares
                @log << "近鉄 share num: #{shares.size} "
                shares[5].buyable = false
                shares[6].buyable = false
                shares[7].buyable = false

              end
            }

            @companies.each { |c| @log << "is #{c.type} " }
            @log << "add latecomercompany. size: #{@latecomer_companies.size} "
            @companies += @latecomer_companies
            @log << "added latecomercompany. size: #{@companies.size} "
            @log << "buyable_bank_owned_companies size: #{buyable_bank_owned_companies.size} "
            @log << "unclosed_companies size: #{@latecomer_companies.select { |c| !c.closed? }.size} "
            @log << "corps size: #{@corporations.size} "

            update_cache(:companies)
          end

          super
        end

        def unowned_purchasable_companies(_entity)
          @companies.select { |c| !c.owned_by_player? }
        end

        # from1824
        # def after_buy_company(player, company, price)
        #   abilities(company, :shares) do |ability|
        #     ability.shares.each do |share|
        #       if share.
        #         float_minor!(share.corporation, company.value)
        #       else
        #         share_pool.buy_shares(player, share, exchange: :free)
        #       end
        #     end
        #   end
        # end


        # # from1824
        # def float_minor!(minor, value)
        #   @bank.spend(value, minor)
        #   @log << "#{minor.name} receives #{value}"
        #   minor.floated = true
        # end
      def after_buy_company(player, company, _price)
        abilities(company, :shares) do |ability|
          ability.shares.each do |share|
            if share.president
              @round.companies_pending_par << company
            else
              share_pool.buy_shares(player, share, exchange: :free)
            end
          end
        end
        abilities(company, :acquire_company) do |ability|
          acquired_company = company_by_id(ability.company)
          acquired_company.owner = player
          player.companies << acquired_company
          @log << "#{player.name} receives #{acquired_company.name}"
          after_buy_company(player, acquired_company, 0)
        end
        acquire_minor(company)
      end

        def acquire_minor(company)
          return unless (minor = @minors.find { |m| m.name == company.sym })
          minor.owner = company.player
          @bank.spend(company.treasury, minor)
          minor.float!
        end
      def city_tokened_by?(city, entity)
        if entity.name == '阪鉄'
          daiki = @minors.find { |m| m.name == '大軌' }
          return city.tokened_by?(daiki)
        end
        super
      end



      end
    end
  end
end
