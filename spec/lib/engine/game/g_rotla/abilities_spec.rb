# frozen_string_literal: true

require './spec/spec_helper'

describe Engine::Game::GRotLA::Abilities do
  let(:game) { Engine::Game::GRotLA::Game.new(%w[a b c d], seed: 123, strict: true) }

  it 'assigns one source-tracked ability to every Minor' do
    game.corporations.select { |corporation| corporation.type == :minor }.each do |minor|
      records = game.rotla_ability_records(minor)

      expect(records.size).to eq(1)
      expect(records.first[:source]).to eq(minor.id)
      expect(records.first[:state]).to eq({})
    end
  end

  it 'moves ability records and their state to a Major without retaining them on closed sources' do
    spacious = game.corporation_by_id('SPA')
    tunneling = game.corporation_by_id('TUN')
    major = game.corporation_by_id('C')
    game.rotla_ability_state(spacious, :spacious)[:marker] = 'preserved'

    game.rotla_transfer_abilities!([spacious, tunneling], major)

    expect(game.rotla_ability_ids(major)).to contain_exactly(:spacious, :tunneling)
    expect(game.rotla_ability_state(major, :spacious)).to eq(marker: 'preserved')
    expect(game.rotla_ability_ids(spacious)).to be_empty
    expect(game.rotla_ability_ids(tunneling)).to be_empty
  end

  it 'increases the train limit for Spacious before and after a merger transfer' do
    spacious = game.corporation_by_id('SPA')
    major = game.corporation_by_id('C')

    expect(game.train_limit(spacious)).to eq(3)

    game.rotla_transfer_abilities!([spacious], major)

    expect(game.train_limit(major)).to eq(1)
  end

  it 'uses a non-blocking graph for Overnight before and after merger transfer' do
    overnight = game.corporation_by_id('OVN')
    major = game.corporation_by_id('C')

    expect(game.graph_for_entity(overnight).no_blocking?).to be(true)
    expect(game.graph_for_entity(game.corporation_by_id('SPA')).no_blocking?).to be(false)

    game.rotla_transfer_abilities!([overnight], major)

    expect(game.graph_for_entity(major).no_blocking?).to be(true)
  end

  it 'does not count a blocked pass-through city as an Overnight stop or revenue center' do
    overnight = game.corporation_by_id('OVN')
    train = game.depot.trains.first
    game.buy_train(overnight, train, :free)
    first = instance_double(Engine::Part::City, visit_cost: 1, city?: true)
    blocked = instance_double(Engine::Part::City, visit_cost: 1, city?: true)
    last = instance_double(Engine::Part::City, visit_cost: 1, city?: true)
    allow(first).to receive(:blocks?).with(overnight).and_return(false)
    allow(blocked).to receive(:blocks?).with(overnight).and_return(true)
    allow(last).to receive(:blocks?).with(overnight).and_return(false)
    route = Struct.new(:train, :corporation, :connection_data, :visited_stops).new(
      train,
      overnight,
      [{ left: first, right: blocked }, { left: blocked, right: last }],
      [first, blocked, last],
    )

    expect { game.check_distance(route, route.visited_stops) }.not_to raise_error
    expect(game.revenue_stops(route)).to contain_exactly(first, last)
    expect(game.route_distance(route)).to eq(2)
  end

  it 'rejects an Overnight route that revisits the same blocked city' do
    overnight = game.corporation_by_id('OVN')
    blocked = instance_double(Engine::Part::City, city?: true, visit_cost: 1)
    endpoint = instance_double(Engine::Part::City, city?: true, visit_cost: 1)
    allow(blocked).to receive(:blocks?).with(overnight).and_return(true)
    allow(endpoint).to receive(:blocks?).with(overnight).and_return(false)
    route = Struct.new(:corporation, :connection_data).new(
      overnight,
      [
        { left: endpoint, right: blocked },
        { left: blocked, right: endpoint },
        { left: endpoint, right: blocked },
      ],
    )
    allow(route).to receive(:visited_stops).and_return([endpoint, blocked])
    allow(route).to receive(:train).and_return(instance_double(Engine::Train, local?: true))

    expect { game.check_other(route) }.to raise_error(Engine::GameError, /same blocked city/)
  end

  it 'uses Overnight when either company in a merger owns it' do
    proposer = game.corporation_by_id('SPA')
    overnight = game.corporation_by_id('OVN')
    city = game.hex_by_id(overnight.coordinates).tile.cities.first
    city.place_token(overnight, overnight.tokens.first, free: true)
    overnight_graph = instance_double(Engine::Graph, connected_nodes: { city => true })
    allow(game).to receive(:rotla_overnight_graph).and_return(overnight_graph)

    expect(game.rotla_merge_connected?(proposer, overnight)).to be(true)
  end

  it 'lets Express make one extra stop only while its corporation owns exactly one train' do
    express = game.corporation_by_id('XPR')
    train = game.depot.trains.first
    game.buy_train(express, train, :free)
    route = Struct.new(:train, :corporation).new(train, express)
    visit = Struct.new(:visit_cost)

    expect { game.check_distance(route, Array.new(3) { visit.new(1) }) }.not_to raise_error
    expect { game.check_distance(route, Array.new(4) { visit.new(1) }) }.to raise_error(Engine::RouteTooLong)

    second_train = game.depot.trains.find { |candidate| candidate.owner == game.depot }
    game.buy_train(express, second_train, :free)

    expect { game.check_distance(route, Array.new(3) { visit.new(1) }) }.to raise_error(Engine::RouteTooLong)
  end

  it 'shows active ability names rather than the former pending placeholder' do
    spacious = game.corporation_by_id('SPA')
    bridging = game.corporation_by_id('BRI')

    expect(game.status_array(spacious)).to include('Abilities: Spacious')
    expect(game.status_array(spacious).join(' ')).not_to include('pending')
    expect(game.status_array(bridging)).to include('Abilities: Bridging (pending)')
  end
end
