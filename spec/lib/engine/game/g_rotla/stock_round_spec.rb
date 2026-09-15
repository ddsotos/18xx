# frozen_string_literal: true

require './spec/spec_helper'

describe Engine::Game::GRotLA::StockRound do
  let(:game_class) do
    Class.new do
      include Engine::Game::GRotLA::StockRound
    end
  end

  it 'constructs the RotLA Stock Round with the canonical steps' do
    game = game_class.new
    round = Object.new
    expect(Engine::Game::GRotLA::Round::Stock)
      .to receive(:new).with(game, Engine::Game::GRotLA::StockRoundSteps.steps).and_return(round)

    expect(game.stock_round).to equal(round)
  end

  it 'hides and disables the engine certificate limit' do
    game = game_class.new

    expect(game.show_game_cert_limit?).to be(false)
    expect(game.cert_limit).to eq(Float::INFINITY)
  end
end
