# frozen_string_literal: true

require './spec/spec_helper'

describe Engine::Game::GRotLA::Game do
  let(:game) { described_class.new(%w[a b c d], seed: 123, strict: true) }

  it 'starts a registered four-player long game from self-contained default settings' do
    expect(Engine.game_by_title('Railways of the Lost Atlas')).to eq(described_class)
    expect(game.players.map(&:cash)).to eq([275, 275, 275, 275])
    expect(game.corporations.size).to eq(18)
    expect(game.hexes.size).to eq(36)
    expect(game.round).to be_a(Engine::Game::GRotLA::Round::Stock)
    expect(game.rotla_minor_tableau.front_ids).to eq(%w[SPA TUN NP])
  end

  it 'provides printed homes for every non-Adaptive Minor and basic cities for Adaptive' do
    minors = game.corporations.select { |corporation| corporation.type == :minor }
    fixed_home_minors = minors.reject { |corporation| corporation.id == 'ADA' }

    expect(fixed_home_minors.map(&:coordinates)).to all(satisfy { |coordinate| game.hex_by_id(coordinate) })
    expect(game.corporation_by_id('ADA').coordinates).to be_nil
    expect(game.rotla_adaptive_home_cities(game.corporation_by_id('ADA'))).not_to be_empty
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

  it 'enables the printed two-lay track allowance' do
    expect(game.tile_lays(game.corporations.first)).to eq(described_class::TILE_LAYS)
  end

  it 'uses the printed yellow, green, purple, gray tile progression' do
    tiles = %i[yellow green purple gray].map do |color|
      Engine::Tile.from_code(color.to_s, color, 'path=a:0,b:2')
    end

    expect(game.upgrades_to_correct_color?(tiles[0], tiles[1])).to be(true)
    expect(game.upgrades_to_correct_color?(tiles[1], tiles[2])).to be(true)
    expect(game.upgrades_to_correct_color?(tiles[2], tiles[3])).to be(true)
    expect(game.upgrades_to_correct_color?(tiles[3], tiles[0])).to be(false)
  end

  it 'preserves star, Eastern Mining, and Northern Port upgrade families' do
    tile = lambda do |tile_id|
      definition = Engine::Game::GRotLA::Map::TILES.fetch(tile_id)
      Engine::Tile.from_code(tile_id, definition.fetch('color'), definition.fetch('code'))
    end

    expect(game.upgrades_to?(tile.call('RLA-Y04'), tile.call('RLA-G20'))).to be(true)
    expect(game.upgrades_to?(tile.call('RLA-G20'), tile.call('RLA-P12'))).to be(true)
    expect(game.upgrades_to?(tile.call('RLA-P12'), tile.call('RLA-X02'))).to be(true)
    expect(game.upgrades_to?(tile.call('RLA-G23'), tile.call('RLA-P13'))).to be(true)
    expect(game.upgrades_to?(tile.call('RLA-P13'), tile.call('RLA-X03'))).to be(true)
    expect(game.upgrades_to?(tile.call('RLA-G24'), tile.call('RLA-P14'))).to be(true)
    expect(game.upgrades_to?(tile.call('RLA-Y04'), tile.call('RLA-G13'))).to be(false)
    expect(game.upgrades_to?(tile.call('RLA-Y02'), tile.call('RLA-G20'))).to be(false)
  end
end
