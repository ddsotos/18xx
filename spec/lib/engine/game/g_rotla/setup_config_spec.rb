# frozen_string_literal: true

require './spec/spec_helper'

describe Engine::Game::GRotLA::SetupConfig do
  # Artificial structural example, not an official map or a playable full-game save.
  let(:data) do
    {
      'schema_version' => 2,
      'ruleset' => 'en-second-printing',
      'mode' => 'long',
      'player_count' => 4,
      'map_manifest_version' => 1,
      'map_id' => 'synthetic-test',
      'minor_tableau' => [%w[SPA ADA BRI OVN], %w[TUN RES EM AGR], %w[NP XPN XPR SUB]],
      'map_manifest' => {
        'map_id' => 'synthetic-test',
        'map_version' => 1,
        'placements' => [{ 'copy_id' => 'test-1', 'origin' => [0, -1], 'rotation' => 2 }],
        'projects' => [{ 'project_copy_id' => 'project-1', 'target_city_id' => 'city-1', 'effect_type' => 'capital' }],
      },
      'setup_journal' => [],
    }
  end

  it 'preserves JSON round trips without changing the input' do
    original = JSON.generate(data)
    config = described_class.new(JSON.parse(original))
    expect(config.to_h).to eq(data)
    expect(JSON.generate(data)).to eq(original)
    expect(described_class.new(JSON.parse(JSON.generate(config.to_h))).to_h).to eq(data)
  end

  it 'owns a snapshot independent of input and exported nested values' do
    data['map_manifest']['placements'][0]['copy_id'] = +'test-1'
    config = described_class.new(data)
    data['map_manifest']['placements'][0]['origin'][0] = 99
    data['map_manifest']['placements'][0]['copy_id'].replace('changed')
    output = config.to_h
    output['map_manifest']['placements'][0]['origin'][1] = 99
    output['map_manifest']['projects'][0]['target_city_id'].replace('changed')
    placement = config.to_h['map_manifest']['placements'][0]
    expect(placement).to eq('copy_id' => 'test-1', 'origin' => [0, -1], 'rotation' => 2)
    expect(config.to_h['map_manifest']['projects'][0]['target_city_id']).to eq('city-1')
  end

  {
    'schema_version' => 1,
    'ruleset' => 'first-printing',
    'mode' => 'short',
    'player_count' => 3,
    'map_manifest_version' => 2,
  }.each do |field, invalid|
    it "rejects unsupported #{field}" do
      data[field] = invalid
      expect { described_class.new(data) }.to raise_error(ArgumentError, /Unsupported RotLA/)
    end
  end

  it 'rejects missing fields and symbol keys instead of silently using defaults' do
    data.delete('map_manifest')
    expect { described_class.new(data) }.to raise_error(ArgumentError, /requires exactly/)
    expect { described_class.new(schema_version: 1) }.to raise_error(ArgumentError, /string keys/)
  end

  it 'reads the existing settings envelope without losing unrelated game settings' do
    settings = { 'seed' => 123, 'rotla' => data }
    expect(described_class.from_settings(settings).to_h).to eq(data)
    expect(settings['seed']).to eq(123)
    expect { described_class.from_settings({}) }.to raise_error(ArgumentError, /Missing settings.rotla/)
    expect { described_class.from_settings('rotla' => nil) }.to raise_error(ArgumentError)
  end

  it 'rejects unknown keys and string versions' do
    data['extra'] = true
    expect { described_class.new(data) }.to raise_error(ArgumentError, /requires exactly/)
    data.delete('extra')
    data['schema_version'] = '1'
    expect { described_class.new(data) }.to raise_error(ArgumentError, /schema_version/)
  end

  it 'rejects mismatched map identities' do
    data['map_manifest']['map_id'] = 'different-map'
    expect { described_class.new(data) }.to raise_error(ArgumentError, %r{identity/version})
  end

  it 'rejects unfinished setup histories' do
    data['setup_journal'] = [{ 'type' => 'place' }]
    expect { described_class.new(data) }.to raise_error(ArgumentError, /finalized fixed maps/)
  end

  it 'rejects an incomplete or duplicate Minor Company tableau' do
    data['minor_tableau'][0].pop
    expect { described_class.new(data) }.to raise_error(ArgumentError, /Minor tableau/)
    data['minor_tableau'][0] << data['minor_tableau'][1][0]
    expect { described_class.new(data) }.to raise_error(ArgumentError, /every Long Game Minor Company/)
  end

  it 'rejects missing placements and duplicate physical copies' do
    data['map_manifest']['placements'] = []
    expect { described_class.new(data) }.to raise_error(ArgumentError, /nonempty array/)
    placement = { 'copy_id' => 'same-copy', 'origin' => [0, 0], 'rotation' => 0 }
    data['map_manifest']['placements'] = [placement, placement.dup]
    expect { described_class.new(data) }.to raise_error(ArgumentError, /Duplicate map copy_id/)
  end

  [[0], [0, 1, 2], [0, '1'], [0, 1.5]].each do |origin|
    it "rejects malformed origin #{origin.inspect}" do
      data['map_manifest']['placements'][0]['origin'] = origin
      expect { described_class.new(data) }.to raise_error(ArgumentError)
    end
  end

  [-1, 6, '0', nil].each do |rotation|
    it "rejects malformed rotation #{rotation.inspect}" do
      data['map_manifest']['placements'][0]['rotation'] = rotation
      expect { described_class.new(data) }.to raise_error(ArgumentError, /rotation/)
    end
  end

  it 'rejects duplicate projects and empty target references' do
    project = data['map_manifest']['projects'][0]
    data['map_manifest']['projects'] << project.dup
    expect { described_class.new(data) }.to raise_error(ArgumentError, /Duplicate project_copy_id/)
    data['map_manifest']['projects'].pop
    project['target_city_id'] = ' '
    expect { described_class.new(data) }.to raise_error(ArgumentError, /target_city_id/)
  end
end
