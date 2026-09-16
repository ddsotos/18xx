# frozen_string_literal: true

require './spec/spec_helper'

describe Engine::Game::GRotLA::Game do
  let(:game) { described_class.new(%w[a b c d], seed: 123, strict: true) }

  it 'starts a registered four-player long game from self-contained default settings' do
    expect(Engine.game_by_title('Railways of the Lost Atlas')).to eq(described_class)
    expect(game.players.map(&:cash)).to eq([275, 275, 275, 275])
    expect(game.corporations.size).to eq(18)
    expect(game.hexes.size).to eq(99)
    expect(game.round).to be_a(Engine::Game::GRotLA::Round::Stock)
    expect(game.rotla_minor_tableau.front_ids).to eq(%w[SPA TUN NP])
  end

  it 'provides printed homes for every non-Adaptive Minor and basic cities for Adaptive' do
    minors = game.corporations.select { |corporation| corporation.type == :minor }
    fixed_home_minors = minors.reject { |corporation| corporation.id == 'ADA' }

    expect(fixed_home_minors.map(&:coordinates)).to all(satisfy { |coordinate| game.hex_by_id(coordinate) })
    expect(game.corporation_by_id('ADA').coordinates).to be_nil
    expect(game.rotla_adaptive_home_cities(game.corporation_by_id('ADA'))).not_to be_empty
    expect(game.rotla_map_builder.cities_by_type(game, :capital).size).to eq(3)
  end

  it 'derives non-Adaptive homes from a completed custom placement journal' do
    setup = Engine::Game::GRotLA::MapSetup.new
    Engine::Game::GRotLA::Map::PIECE_ORIGINS.each_index do |slot_index|
      setup.place!(slot_index: slot_index, rotation: 0)
    end
    3.times { setup.choose_capital!(target_city_id: setup.capital_candidates.first) }
    custom_game = described_class.new(%w[a b c d], settings: { 'rotla' => setup.rotla_settings }, seed: 123)

    fixed_home_minors = custom_game.corporations.select do |corporation|
      corporation.type == :minor && corporation.id != Engine::Game::GRotLA::Entities::ADAPTIVE_ID
    end
    expect(fixed_home_minors.map(&:coordinates))
      .to eq(custom_game.rotla_map_builder.company_home_coordinates)
  end

  it 'keeps the generated fixed map and settings through clone' do
    copy = game.clone([])

    expect(copy.rotla_settings).to eq(game.rotla_settings)
    expect(copy.hexes.map(&:coordinates)).to eq(game.hexes.map(&:coordinates))
    expect(copy.rotla_minor_tableau.snapshot).to eq(game.rotla_minor_tableau.snapshot)
  end

  it 'ends after six cycles without exporting after the final cycle' do
    5.times { game.finish_cycle! }
    final_train_count = game.depot.upcoming.size

    expect(game.turn).to eq(6)
    expect(game.finished).to be(false)

    game.finish_cycle!

    expect(game.finished).to be(true)
    expect(game.depot.upcoming.size).to eq(final_train_count)
  end

  it 'builds the ability-neutral operating step order' do
    steps = game.operating_round(1).steps.map(&:class)

    expect(steps).to include(
      Engine::Game::GRotLA::Step::LeadoffTrain,
      Engine::Game::GRotLA::Step::IssueOrRedeem,
      Engine::Step::Route,
      Engine::Game::GRotLA::Step::Dividend,
      Engine::Step::BuyTrain,
    )
  end
end
