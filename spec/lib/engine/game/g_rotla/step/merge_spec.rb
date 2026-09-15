# frozen_string_literal: true

require './spec/spec_helper'

describe Engine::Game::GRotLA::Step::Merge do
  let(:game) { Engine::Game::GRotLA::Game.new(%w[a b c d], seed: 123, strict: true) }
  let(:round_class) { Struct.new(:entities, :entity_index) }

  def start_corporation(corporation, owner:, price:, cash:)
    share_price = game.stock_market.par_prices.find { |candidate| candidate.price == price }
    game.stock_market.set_par(corporation, share_price)
    game.share_pool.transfer_shares(corporation.presidents_share.to_bundle, owner)
    corporation.ipoed = true
    corporation.floated = true
    game.bank.spend(cash, corporation)
    city = game.hex_by_id(corporation.coordinates).tile.cities.first
    city.place_token(corporation, corporation.tokens.first, free: true)
  end

  it 'converts shares, average price, cash, and home hubs into an unused Major' do
    first = game.corporation_by_id('SPA')
    second = game.corporation_by_id('TUN')
    major = game.corporation_by_id('C')
    start_corporation(first, owner: game.players[0], price: 70, cash: 40)
    start_corporation(second, owner: game.players[1], price: 90, cash: 60)
    round = round_class.new([first, second], 0)
    step = described_class.new(game, round)
    choice = "merge:#{second.id}:#{major.id}"

    expect(step.choices).to include(choice)
    step.process_choose(Engine::Action::Choose.new(first, choice: choice))

    expect(first).to be_closed
    expect(second).to be_closed
    expect(major).to be_floated
    expect(major.share_price.price).to eq(80)
    expect(major.cash).to eq(100)
    expect(major.owner).to eq(game.players[0])
    expect(game.players[0].percent_of(major)).to eq(20)
    expect(game.players[1].percent_of(major)).to eq(20)
    expect(major.tokens.count(&:used)).to eq(2)
  end

  it 'rejects stale and malformed merger choices without changing corporations' do
    first = game.corporation_by_id('SPA')
    second = game.corporation_by_id('TUN')
    start_corporation(first, owner: game.players[0], price: 70, cash: 40)
    start_corporation(second, owner: game.players[1], price: 90, cash: 60)
    step = described_class.new(game, round_class.new([first, second], 0))
    before = [first.cash, second.cash, game.corporation_by_id('C').ipoed]

    expect { step.process_choose(Engine::Action::Choose.new(first, choice: 'merge:bad:C')) }
      .to raise_error(Engine::GameError)
    expect([first.cash, second.cash, game.corporation_by_id('C').ipoed]).to eq(before)
  end
end
