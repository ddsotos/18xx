# frozen_string_literal: true

require './spec/spec_helper'

describe Engine::Game::GRotLA::Setup do
  # Use a real engine game as a harness without registering a fictitious RotLA title.
  let(:game_class) do
    Class.new(Engine::Game::G1889::Game) do
      include Engine::Game::GRotLA::Setup

      attr_reader :config_at_hex_init

      def init_hexes(companies, corporations)
        @config_at_hex_init = rotla_setup_config.to_h
        super
      end
    end
  end
  let(:names) { %w[a b c d] }
  let(:settings) do
    {
      'rotla' => {
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
          'placements' => [{ 'copy_id' => 'test-1', 'origin' => [0, 0], 'rotation' => 0 }],
          'projects' => [],
        },
        'setup_journal' => [],
      },
      'seed' => 123,
      'extra' => { 'nested' => ['preserved'] },
    }
  end
  let(:game) { game_class.new(names, settings: settings, seed: 123, strict: true, use_engine_v2: true) }

  it 'makes validated settings available before engine hex/graph initialization' do
    expect(game.config_at_hex_init).to eq(settings['rotla'])
    expect(game.rotla_minor_tableau.snapshot).to eq(settings['rotla']['minor_tableau'])
    expect(game.hexes).not_to be_empty
    expect(game.graph).to be_a(Engine::Graph)
  end

  it 'validates the actual player count and rejects missing settings before initialization' do
    expect { game_class.new(%w[a b c], settings: settings) }.to raise_error(ArgumentError, /four players/)
    expect { game_class.new(names) }.to raise_error(ArgumentError, /Missing settings.rotla/)
  end

  it 'loads through the real Game.load settings forwarding path' do
    allow(Engine).to receive(:game_by_title).with('RotLA harness').and_return(game_class)
    loaded = Engine::Game.load({
                                 'title' => 'RotLA harness',
                                 'id' => 'test',
                                 'players' => names.map { |name| { 'name' => name } },
                                 'settings' => settings,
                                 'actions' => [],
                               })
    expect(loaded.config_at_hex_init).to eq(settings['rotla'])
    expect(loaded.seed).to eq(123)
  end

  it 'keeps input, exported settings and cloned games independent' do
    original = game.rotla_setup_config.to_h
    settings['rotla']['map_manifest']['placements'][0]['origin'][0] = 99
    settings['extra']['nested'] << 'changed'
    exported = game.rotla_settings
    exported['rotla']['map_id'] = 'changed'
    exported['extra']['nested'] << 'changed'
    copy = game.clone([])
    expect(copy.rotla_setup_config.to_h).to eq(original)
    expect(copy.rotla_settings['extra']['nested']).to eq(['preserved'])
    expect(copy.rotla_setup_config).not_to equal(game.rotla_setup_config)
    expect(copy.rotla_minor_tableau).not_to equal(game.rotla_minor_tableau)
    expect(copy.rotla_minor_tableau.snapshot).to eq(game.rotla_minor_tableau.snapshot)
    expect(copy.use_engine_v2).to be(true)
  end

  it 'replays actions and preserves setup when undo reconstructs the game' do
    game.process_action(Engine::Action::Pass.new(game.current_entity)).maybe_raise!
    after_pass = game.current_entity.id
    copy = game.clone(game.raw_actions)
    expect(copy.current_entity.id).to eq(after_pass)
    expect(copy.raw_actions).to eq(game.raw_actions)
    undone = game.process_action(Engine::Action::Undo.new(game.players.first)).maybe_raise!
    expect(undone.rotla_setup_config.to_h).to eq(settings['rotla'])
    expect(undone.current_entity.id).to eq('a')
    expect(undone.use_engine_v2).to be(true)
  end

  it 'persists generated seed and effective options through JSON export' do
    generated = game_class.new(names, settings: settings, use_engine_v2: true)
    exported = JSON.parse(JSON.generate(generated.rotla_settings))
    expect(exported['seed']).to eq(generated.seed)
    expect(exported['use_engine_v2']).to be(true)
    expect(exported['rotla']).to eq(settings['rotla'])
    expect(generated.instance_variable_get(:@init_kwargs)[:settings]).to eq(exported)
    expect(generated.clone([]).seed).to eq(generated.seed)
  end
end
