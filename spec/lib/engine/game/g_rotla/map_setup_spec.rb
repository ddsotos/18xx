# frozen_string_literal: true

require './spec/spec_helper'

describe Engine::Game::GRotLA::MapSetup do
  def complete_map_setup
    setup = described_class.new
    Engine::Game::GRotLA::Map::PIECE_ORIGINS.each_index do |slot_index|
      setup.place!(slot_index: slot_index, rotation: 0)
    end
    3.times { setup.choose_capital!(target_city_id: setup.capital_candidates.first) }
    setup
  end

  it 'places every provisional map tile in four-player turn order' do
    setup = described_class.new

    expect(setup.phase).to eq(:map_tiles)
    expect(setup.current_copy_id).to eq('long4-01')
    expect(setup.current_actor_index).to eq(0)

    setup.place!(slot_index: 0, rotation: 0)
    expect(setup.current_copy_id).to eq('long4-02')
    expect(setup.current_actor_index).to eq(1)
    expect(setup.legal_slot_indices(0)).not_to include(0)
  end

  it 'resolves all three Capital tiles before producing finalized settings' do
    setup = complete_map_setup
    settings = setup.rotla_settings
    config = Engine::Game::GRotLA::SetupConfig.new(settings)
    builder = Engine::Game::GRotLA::MapBuilder.new(config, catalog: Engine::Game::GRotLA::Map::MAP_CATALOG)

    expect(setup).to be_complete
    expect(settings['setup_journal'].size).to eq(36)
    expect(settings['map_manifest']['projects'].map { |project| project['project_copy_id'] })
      .to eq(%w[capital-01 capital-02 capital-03])
    expect(builder.coordinates_by_type(:capital).size).to eq(3)
  end

  it 'replays the journal to the same manifest and rejects an altered actor' do
    setup = complete_map_setup
    replay = described_class.new(journal: setup.journal)
    altered = setup.journal
    altered[4]['actor_index'] = 0

    expect(replay.rotla_settings['map_manifest']).to eq(setup.rotla_settings['map_manifest'])
    expect { described_class.new(journal: altered) }.to raise_error(ArgumentError, /out of turn/)
  end

  it 'rejects occupied slots, overlapping rotations, and repeated Capital targets' do
    setup = described_class.new
    setup.place!(slot_index: 0, rotation: 0)

    expect { setup.place!(slot_index: 0, rotation: 0) }.to raise_error(ArgumentError, /not legal/)
    expect(setup.legal_slot_indices(2)).not_to include(1)

    capital_setup = described_class.new
    Engine::Game::GRotLA::Map::PIECE_ORIGINS.each_index do |slot_index|
      capital_setup.place!(slot_index: slot_index, rotation: 0)
    end
    target = capital_setup.capital_candidates.first
    capital_setup.choose_capital!(target_city_id: target)
    expect { capital_setup.choose_capital!(target_city_id: target) }
      .to raise_error(ArgumentError, /not a basic city/)
  end
end
