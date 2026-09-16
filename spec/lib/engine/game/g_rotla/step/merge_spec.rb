# frozen_string_literal: true

require './spec/spec_helper'

describe Engine::Game::GRotLA::Step::Merge do
  let(:game) { Engine::Game::GRotLA::Game.new(%w[a b c d], seed: 123, strict: true) }
  let(:round_class) do
    Struct.new(:entities, :entity_index, :pending_merger, :rejected_mergers, :pending_merged_corporation)
  end

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

  def merger_step(first, second)
    round = round_class.new([first, second], 0, nil, [], nil)
    [described_class.new(game, round), round]
  end

  def accept_merger(step, first, second, major)
    step.process_choose(Engine::Action::Choose.new(first, choice: "merge:#{second.id}"))
    step.process_choose(Engine::Action::Choose.new(second.owner, choice: 'accept'))
    step.process_choose(Engine::Action::Choose.new(first.owner, choice: "major:#{major.id}"))
  end

  it 'requires the partner president to consent before the new president chooses a Major' do
    first = game.corporation_by_id('SPA')
    second = game.corporation_by_id('TUN')
    major = game.corporation_by_id('C')
    start_corporation(first, owner: game.players[0], price: 70, cash: 40)
    start_corporation(second, owner: game.players[1], price: 90, cash: 60)
    allow(game).to receive(:rotla_merge_connected?).and_return(true)
    step, round = merger_step(first, second)

    expect(step.choices).to include("merge:#{second.id}")
    step.process_choose(Engine::Action::Choose.new(first, choice: "merge:#{second.id}"))

    expect(round.pending_merger[:phase]).to eq(:consent)
    expect(step.active_entities).to eq([second.owner])
    expect(step.choices.keys).to contain_exactly('accept', 'reject')

    step.process_choose(Engine::Action::Choose.new(second.owner, choice: 'accept'))

    expect(round.pending_merger[:phase]).to eq(:choose_major)
    expect(step.active_entities).to eq([first.owner])
    expect(step.choices).to include("major:#{major.id}")

    step.process_choose(Engine::Action::Choose.new(first.owner, choice: "major:#{major.id}"))

    expect(first).to be_closed
    expect(second).to be_closed
    expect(major).to be_floated
    expect(major.share_price.price).to eq(80)
    expect(major.cash).to eq(100)
    expect(major.owner).to eq(game.players[0])
    expect(game.players[0].percent_of(major)).to eq(20)
    expect(game.players[1].percent_of(major)).to eq(20)
    expect(major.tokens.count(&:used)).to eq(2)
    expect(game.rotla_ability_ids(major)).to contain_exactly(:spacious, :tunneling)
    expect(game.rotla_ability_ids(first)).to be_empty
    expect(game.rotla_ability_ids(second)).to be_empty
    expect(round.pending_merger).to be_nil
  end

  it 'prevents either ordering of a rejected pair from being proposed again in the same round' do
    first = game.corporation_by_id('SPA')
    second = game.corporation_by_id('TUN')
    start_corporation(first, owner: game.players[0], price: 70, cash: 40)
    start_corporation(second, owner: game.players[1], price: 90, cash: 60)
    allow(game).to receive(:rotla_merge_connected?).and_return(true)
    step, round = merger_step(first, second)

    step.process_choose(Engine::Action::Choose.new(first, choice: "merge:#{second.id}"))
    step.process_choose(Engine::Action::Choose.new(second.owner, choice: 'reject'))

    expect(first).not_to be_closed
    expect(second).not_to be_closed
    expect(round.rejected_mergers).to eq(['SPA:TUN'])

    step.unpass!
    round.entity_index = 1
    expect(step.choices).not_to include("merge:#{first.id}")
  end

  it 'offers only partners connected by an unblocked route, independent of train distance' do
    first = game.corporation_by_id('SPA')
    second = game.corporation_by_id('TUN')
    start_corporation(first, owner: game.players[0], price: 70, cash: 0)
    start_corporation(second, owner: game.players[1], price: 70, cash: 0)
    partner_city = second.tokens.first.city
    graph = instance_double(Engine::Graph)
    allow(game).to receive(:graph_for_entity).with(first).and_return(graph)
    allow(graph).to receive(:connected_nodes).with(first).and_return(partner_city => true)
    step, = merger_step(first, second)

    expect(game.rotla_merge_connected?(first, second)).to be(true)
    expect(step.choices).to include("merge:#{second.id}")

    allow(graph).to receive(:connected_nodes).with(first).and_return({})
    expect(game.rotla_merge_connected?(first, second)).to be(false)
    expect(step.choices).to be_empty
    expect(step.actions(first)).to eq(['pass'])
  end

  it 'rejects stale and malformed choices without changing corporations' do
    first = game.corporation_by_id('SPA')
    second = game.corporation_by_id('TUN')
    start_corporation(first, owner: game.players[0], price: 70, cash: 40)
    start_corporation(second, owner: game.players[1], price: 90, cash: 60)
    allow(game).to receive(:rotla_merge_connected?).and_return(true)
    step, round = merger_step(first, second)
    before = [first.cash, second.cash, game.corporation_by_id('C').ipoed]

    expect { step.process_choose(Engine::Action::Choose.new(first, choice: 'merge:bad:extra')) }
      .to raise_error(Engine::GameError)

    step.process_choose(Engine::Action::Choose.new(first, choice: "merge:#{second.id}"))
    allow(game).to receive(:rotla_merge_connected?).and_return(false)
    expect { step.process_choose(Engine::Action::Choose.new(second.owner, choice: 'accept')) }
      .to raise_error(Engine::GameError, /no longer available/)

    expect(round.pending_merger[:phase]).to eq(:consent)
    expect([first.cash, second.cash, game.corporation_by_id('C').ipoed]).to eq(before)
  end

  it 'automatically records consent when one player is president of both Minors' do
    first = game.corporation_by_id('SPA')
    second = game.corporation_by_id('TUN')
    start_corporation(first, owner: game.players[0], price: 70, cash: 0)
    start_corporation(second, owner: game.players[0], price: 70, cash: 0)
    allow(game).to receive(:rotla_merge_connected?).and_return(true)
    step, round = merger_step(first, second)

    step.process_choose(Engine::Action::Choose.new(first, choice: "merge:#{second.id}"))

    expect(round.pending_merger[:phase]).to eq(:choose_major)
    expect(step.active_entities).to eq([game.players[0]])
  end

  it 'leaves an over-limit merged Major pending for immediate train cleanup' do
    first = game.corporation_by_id('SPA')
    second = game.corporation_by_id('TUN')
    major = game.corporation_by_id('C')
    start_corporation(first, owner: game.players[0], price: 70, cash: 0)
    start_corporation(second, owner: game.players[1], price: 70, cash: 0)
    game.depot.trains.first(2).each { |train| game.buy_train(first, train, :free) }
    game.buy_train(second, game.depot.trains.find { |train| train.owner == game.depot }, :free)
    allow(game).to receive(:rotla_merge_connected?).and_return(true)
    allow(game).to receive(:train_limit).with(major).and_return(2)
    step, round = merger_step(first, second)

    accept_merger(step, first, second, major)

    expect(major.trains.size).to eq(3)
    expect(round.pending_merged_corporation).to eq(major)
  end
end

describe Engine::Game::GRotLA::Step::DiscardMergedTrains do
  let(:game) { Engine::Game::GRotLA::Game.new(%w[a b c d], seed: 123, strict: true) }
  let(:round_class) { Struct.new(:pending_merged_corporation) }

  it 'blocks on the merged Major until its train count is within its limit' do
    major = game.corporation_by_id('C')
    major.ipoed = true
    major.floated = true
    game.depot.trains.first(3).each { |train| game.buy_train(major, train, :free) }
    allow(game).to receive(:train_limit).with(major).and_return(2)
    round = round_class.new(major)
    step = described_class.new(game, round)
    train = major.trains.first

    expect(step.active_entities).to eq([major])
    expect(step.actions(major)).to eq(['discard_train'])

    step.process_discard_train(Engine::Action::DiscardTrain.new(major, train: train))

    expect(train.owner).to eq(game.depot)
    expect(major.trains.size).to eq(2)
    expect(round.pending_merged_corporation).to be_nil
    expect(step).to be_passed
  end
end
