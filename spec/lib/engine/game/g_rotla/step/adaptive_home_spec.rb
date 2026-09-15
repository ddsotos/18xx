# frozen_string_literal: true

require './spec/spec_helper'

describe Engine::Game::GRotLA::Step::AdaptiveHome do
  let(:player) { Engine::Player.new('p1', 'President') }
  let(:adaptive) do
    Engine::Corporation.new(
      sym: 'ADA',
      name: 'Adaptive',
      type: 'minor',
      shares: [40, 20, 20, 20],
      tokens: [0],
    )
  end
  let(:other) { Engine::Corporation.new(sym: 'OTH', name: 'Other', tokens: [0, 0, 0, 0]) }
  let(:other_two) { Engine::Corporation.new(sym: 'OTH2', name: 'Other Two', tokens: [0]) }

  let(:game_class) do
    Class.new do
      attr_reader :cities, :cleared_graph_for, :log
      attr_accessor :adaptive_home_candidates

      def initialize(cities)
        @cities = cities
        @adaptive_home_candidates = cities
        @log = []
      end

      # This is the map contract: capital and special-company cities are
      # omitted here rather than inferred from map coordinates in the step.
      def rotla_adaptive_home_cities(_corporation)
        @adaptive_home_candidates
      end

      def city_by_id(id)
        @cities.find { |city| city.id == id }
      end

      def clear_graph_for_entity(corporation)
        @cleared_graph_for = corporation
      end
    end
  end

  let(:round_class) do
    Struct.new(:pending_adaptive_home, :entity_index)
  end

  def make_city(tile_id, index)
    tile = Engine::Tile.for(tile_id, index: index)
    Engine::Hex.new("#{('A'..'Z').to_a[index]}1", tile: tile)
    tile.cities.first
  end

  def build_step
    legal = make_city('57', 0) # a basic city with existing track
    reserved = make_city('57', 1)
    reserved.add_reservation!(other)
    occupied = make_city('57', 2)
    occupied.place_token(other, other.next_token, free: true)
    full = make_city('14', 3) # two city slots, both occupied
    full.place_token(other, other.next_token, free: true)
    full.place_token(other_two, other_two.next_token, free: true)
    partial = make_city('14', 4) # open slot, but the basic city is not empty
    partial.place_token(other, other.next_token, free: true)
    capital = make_city('57', 5)

    game = game_class.new([legal, reserved, occupied, full, partial, capital])
    # The game hook excludes map-specific capital/special cities.
    game.adaptive_home_candidates = [legal, reserved, occupied, full, partial]
    round = round_class.new(adaptive, 2)
    adaptive.owner = player
    step = described_class.new(game, round)
    [step, game, round, legal]
  end

  it 'blocks on the president and exposes only legal stable city IDs' do
    step, game, = build_step

    expect(step.blocks?).to be(true)
    expect(step.active_entities).to eq([player])
    expect(step.actions(player)).to eq(['choose'])
    expect(step.actions(Engine::Player.new('p2', 'Other'))).to eq([])
    expect(step.choices.keys).to eq([game.cities.first.id])
  end

  it 'is idle when no Adaptive home is pending' do
    step, _game, round, = build_step
    round.pending_adaptive_home = nil

    expect(step.blocks?).to be(false)
    expect(step.blocking?).to be(false)
    expect(step.active_entities).to eq([])
    expect(step.actions(player)).to eq([])
    expect(step.choices).to eq({})
  end

  it 'rejects a non-president without changing the token or pending state' do
    step, _game, round, legal = build_step
    outsider = Engine::Player.new('p2', 'Outsider')

    expect { step.process_choose(Engine::Action::Choose.new(outsider, choice: legal.id)) }
      .to raise_error(Engine::GameError, /president/)
    expect(round.pending_adaptive_home).to equal(adaptive)
    expect(adaptive.tokens.first.used).to be(false)
  end

  it 'rejects an illegal city without changing pending state' do
    step, game, round, = build_step
    occupied = game.cities[2]

    expect { step.process_choose(Engine::Action::Choose.new(player, choice: occupied.id)) }
      .to raise_error(Engine::GameError, /not legal/)
    expect(round.pending_adaptive_home).to equal(adaptive)
  end

  it 'revalidates a city that became occupied after choices were shown' do
    step, game, round, legal = build_step
    expect(step.choices).to have_key(legal.id)
    legal.place_token(other, other.next_token, free: true)

    expect { step.process_choose(Engine::Action::Choose.new(player, choice: legal.id)) }
      .to raise_error(Engine::GameError, /not legal/)
    expect(round.pending_adaptive_home).to equal(adaptive)
    expect(game.cleared_graph_for).to be_nil
  end

  it 'rejects malformed duplicate candidate IDs' do
    step, game, = build_step
    legal = game.cities.first
    game.adaptive_home_candidates = [legal, legal]

    expect { step.choices }.to raise_error(Engine::GameError, /duplicate city IDs/)
  end

  it 'rejects a pending corporation other than Adaptive' do
    step, _game, round, legal = build_step
    other.owner = player
    round.pending_adaptive_home = other

    expect { step.process_choose(Engine::Action::Choose.new(player, choice: legal.id)) }
      .to raise_error(Engine::GameError, /not Adaptive/)
    expect(round.pending_adaptive_home).to equal(other)
  end

  it 'places a free hub, records the city hex, and clears pending state' do
    step, game, round, legal = build_step
    cash_before = adaptive.cash

    step.process_choose(Engine::Action::Choose.new(player, choice: legal.id))

    expect(round.pending_adaptive_home).to be_nil
    expect(legal.tokened_by?(adaptive)).to be(true)
    expect(adaptive.tokens.first.city).to equal(legal)
    expect(adaptive.coordinates).to eq(legal.hex.id)
    expect(adaptive.cash).to eq(cash_before)
    expect(game.cleared_graph_for).to equal(adaptive)
    expect(round.entity_index).to eq(2)
    expect(step.blocks?).to be(false)
  end

  it 'replays the same stable city ID from a serialized Choose action' do
    step, _game, round, legal = build_step
    original = Engine::Action::Choose.new(player, choice: legal.id)
    replayed_args = Engine::Action::Choose.h_to_args(original.to_h, nil)

    step.process_choose(Engine::Action::Choose.new(player, **replayed_args))

    expect(adaptive.tokens.first.city.id).to eq(original.to_h['choice'])
    expect(round.pending_adaptive_home).to be_nil
  end
end
