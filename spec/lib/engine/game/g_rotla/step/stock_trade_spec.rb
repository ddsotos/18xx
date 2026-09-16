# frozen_string_literal: true

require './spec/spec_helper'

describe Engine::Game::GRotLA::Step::StockTrade do
  let(:round_class) do
    Class.new do
      attr_reader :entities
      attr_accessor :entity_index, :players_sold, :players_bought, :current_actions, :bought_from_ipo,
                    :players_history, :pass_order, :last_to_act, :rotla_sold_corporations

      def initialize(entities)
        @entities = entities
        @entity_index = 0
        @pass_order = []
      end
    end
  end

  let(:game_class) do
    Class.new do
      attr_reader :players, :corporations, :stock_market, :share_pool, :bank, :log
      attr_accessor :round

      def initialize
        @log = []
        @players = %w[p1 p2 p3 p4].map { |id| Engine::Player.new(id, id.upcase) }
        @bank = Engine::Bank.new(10_000, log: @log)
        @players.each { |player| @bank.spend(300, player) }
        @corporations = %w[SPA TUN].map do |id|
          definition = Engine::Game::GRotLA::Entities::MINOR_COMPANIES.find { |company| company[:sym] == id }
          Engine::Corporation.new(**definition.reject { |key| key == :ability_id })
        end
        @stock_market = Engine::StockMarket.new(Engine::Game::GRotLA::GameData::MARKET, [])
        @share_pool = Engine::SharePool.new(self)
        @operated = {}
      end

      def found!(corporation, president: players.first, price: 70)
        share_price = stock_market.par_prices.find { |candidate| candidate.price == price }
        stock_market.set_par(corporation, share_price)
        share_pool.transfer_shares(corporation.presidents_share.to_bundle, president)
        corporation.ipoed = true
        corporation.floated = true
      end

      def mark_operated(corporation)
        @operated[corporation] = true
      end

      def rotla_corporation_operated?(corporation)
        @operated[corporation]
      end

      def num_certs(player)
        player.shares.size
      end

      def bundles_for_corporation(share_holder, corporation)
        shares = share_holder.shares_of(corporation)
        shares.each_index.map { |index| Engine::ShareBundle.new(shares.take(index + 1)) }
      end

      def cert_limit(_player)
        0
      end

      def possible_presidents
        players
      end

      def shares_for_presidency_swap(shares, number)
        shares.take(number)
      end

      def sold_shares_destination(_corporation)
        :market
      end

      def can_swap_for_presidents_share_directly_from_corporation?
        false
      end

      def format_currency(amount)
        "#{amount}金"
      end
    end
  end

  def build_step
    game = game_class.new
    round = round_class.new(game.players)
    game.round = round
    step = described_class.new(game, round)
    step.round_state.each { |key, value| round.public_send("#{key}=", value) }
    step.setup
    [step, game, round]
  end

  def transfer_share(game, share, owner)
    game.share_pool.transfer_shares(share.to_bundle, owner)
  end

  it 'offers stock actions to only the normal current player and never offers par' do
    step, game, = build_step
    corporation = game.corporations.first
    game.found!(corporation)

    expect(step.actions(game.players.first)).to contain_exactly('buy_shares', 'pass')
    expect(step.actions(game.players[1])).to be_empty
  end

  it 'buys one treasury share at the current market price, pays treasury, and ends the turn' do
    step, game, = build_step
    corporation = game.corporations.first
    buyer = game.players.first
    game.found!(corporation, president: game.players[1], price: 70)
    game.stock_market.move_right(corporation)
    share = corporation.treasury_shares.first
    player_cash = buyer.cash
    treasury_cash = corporation.cash

    step.process_buy_shares(Engine::Action::BuyShares.new(buyer, shares: share))

    expect(buyer.cash).to eq(player_cash - 80)
    expect(corporation.cash).to eq(treasury_cash + 80)
    expect(buyer.percent_of(corporation)).to eq(20)
    expect(step).to be_passed
  end

  it 'does not apply an Engine certificate limit to a legal purchase' do
    step, game, = build_step
    corporation = game.corporations.first
    buyer = game.players.first
    game.found!(corporation, president: game.players[1])
    share = corporation.treasury_shares.first

    expect(game.num_certs(buyer)).to eq(0)
    expect(game.cert_limit(buyer)).to eq(0)
    expect(step.can_buy?(buyer, share.to_bundle)).to be(true)
  end

  it 'pays the bank when buying a market share' do
    step, game, = build_step
    corporation = game.corporations.first
    buyer = game.players.first
    game.found!(corporation, president: game.players[1])
    market_share = corporation.treasury_shares.first
    transfer_share(game, market_share, game.share_pool)
    bank_cash = game.bank.cash

    step.process_buy_shares(Engine::Action::BuyShares.new(buyer, shares: market_share))

    expect(game.bank.cash).to eq(bank_cash + 70)
    expect(market_share.owner).to eq(buyer)
  end

  it 'rejects a second common share when it would exceed sixty percent ownership' do
    step, game, = build_step
    corporation = game.corporations.first
    president = game.players.first
    game.found!(corporation, president: president)
    share = corporation.treasury_shares.first
    transfer_share(game, share, president)
    candidate = corporation.treasury_shares.first.to_bundle

    expect(step.can_buy?(president, candidate)).to be(false)
    expect { step.process_buy_shares(Engine::Action::BuyShares.new(president, shares: candidate.shares)) }
      .to raise_error(Engine::GameError, /Cannot buy/)
  end

  it 'rejects sales until the corporation has completed an operating turn' do
    step, game, = build_step
    corporation = game.corporations.first
    seller = game.players.first
    game.found!(corporation, president: game.players[1])
    share = corporation.treasury_shares.first
    transfer_share(game, share, seller)
    before = [seller.cash, share.owner, corporation.share_price]

    expect { step.process_sell_shares(Engine::Action::SellShares.new(seller, shares: [share])) }
      .to raise_error(Engine::GameError, /Cannot sell/)
    expect([seller.cash, share.owner, corporation.share_price]).to eq(before)
  end

  it 'prices all same-company sales before one end-of-turn stock-price drop' do
    step, game, = build_step
    corporation = game.corporations.first
    seller = game.players.first
    game.found!(corporation, president: game.players[1])
    game.mark_operated(corporation)
    shares = corporation.treasury_shares.take(2)
    shares.each { |share| transfer_share(game, share, seller) }
    cash = seller.cash

    shares.each do |share|
      step.process_sell_shares(Engine::Action::SellShares.new(seller, shares: [share]))
    end
    expect(seller.cash).to eq(cash + 140)
    expect(corporation.share_price.price).to eq(70)

    step.process_pass(Engine::Action::Pass.new(seller))
    expect(corporation.share_price.price).to eq(60)
  end

  it 'allows selling one company and buying another, but forbids rebuying a company sold in the stock round' do
    step, game, = build_step
    seller = game.players.first
    sold_corporation, bought_corporation = game.corporations
    game.found!(sold_corporation, president: game.players[1])
    game.found!(bought_corporation, president: game.players[2])
    game.mark_operated(sold_corporation)
    sold_share = sold_corporation.treasury_shares.first
    transfer_share(game, sold_share, seller)

    step.process_sell_shares(Engine::Action::SellShares.new(seller, shares: [sold_share]))
    expect(step.can_buy?(seller, sold_share.to_bundle)).to be(false)

    treasury_share = bought_corporation.treasury_shares.first
    step.process_buy_shares(Engine::Action::BuyShares.new(seller, shares: treasury_share))
    expect(treasury_share.owner).to eq(seller)
    expect(step).to be_passed
    expect(sold_corporation.share_price.price).to eq(60)
  end

  it 'rejects pool overflow, presidency loss, wrong actors, and price modifiers before mutation' do
    step, game, = build_step
    corporation = game.corporations.first
    president = game.players.first
    game.found!(corporation, president: president)
    game.mark_operated(corporation)
    two_market_shares = corporation.treasury_shares.take(2)
    two_market_shares.each { |share| transfer_share(game, share, game.share_pool) }
    president_bundle = corporation.presidents_share.to_bundle
    before = [president.cash, president_bundle.owner, game.share_pool.percent_of(corporation)]

    expect { step.process_sell_shares(Engine::Action::SellShares.new(president, shares: president_bundle.shares)) }
      .to raise_error(Engine::GameError, /Cannot sell/)
    expect([president.cash, president_bundle.owner, game.share_pool.percent_of(corporation)]).to eq(before)

    stale_share = corporation.treasury_shares.first
    stale_action = Engine::Action::BuyShares.new(president, shares: stale_share, share_price: 1)
    expect { step.process_buy_shares(stale_action) }.to raise_error(Engine::GameError, /Cannot buy/)
    expect(stale_share.owner).to eq(corporation)

    wrong_actor = game.players[1]
    expect { step.process_buy_shares(Engine::Action::BuyShares.new(wrong_actor, shares: stale_share)) }
      .to raise_error(Engine::GameError, /current player/)
    expect(stale_share.owner).to eq(corporation)
  end
end
