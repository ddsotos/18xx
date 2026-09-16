# frozen_string_literal: true

require './spec/spec_helper'
require './lib/engine/game/g_rotla/track_tile_manifest'

describe Engine::Game::GRotLA::TrackTileManifest do
  subject(:tiles) { described_class::TILES }

  it 'accounts for all 135 physical track tiles in the rulebook component list' do
    expect(tiles.size).to eq(54)
    expect(described_class::TOTAL_COUNT).to eq(135)
    expect(described_class::COLOR_COUNTS).to eq(
      yellow: 55,
      green: 43,
      purple: 27,
      gray: 5,
      blue: 5,
    )
  end

  it 'assigns a stable unique ID and source group to every illustrated type' do
    expect(tiles.map { |tile| tile[:id] }.uniq.size).to eq(tiles.size)
    expect(tiles.map { |tile| tile[:source_group] }.sort).to eq((1..54).to_a)
    expect(tiles).to all(
      satisfy {
        |tile| tile[:count].positive? &&
          tile[:source_image].is_a?(Integer) &&
          tile[:source_top].size == 2
      },
    )
  end

  it 'matches the five non-upgradable bridge tiles described by the rules' do
    bridges = tiles.select { |tile| tile[:color] == :blue }

    expect(bridges.to_h { |tile| [tile[:geometry], tile[:count]] }).to eq(
      bridge_broad_curve: 2,
      bridge_straight: 2,
      bridge_sharp_curve: 1,
    )
  end
end
