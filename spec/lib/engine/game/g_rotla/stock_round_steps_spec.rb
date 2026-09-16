# frozen_string_literal: true

require './spec/spec_helper'

describe Engine::Game::GRotLA::StockRoundSteps do
  it 'keeps founding, the conditional Adaptive blocker, and ordinary trading in their required order' do
    expect(described_class.steps).to eq(
      [
        Engine::Game::GRotLA::Step::FoundingAuction,
        Engine::Game::GRotLA::Step::AdaptiveHome,
        Engine::Game::GRotLA::Step::StockTrade,
      ],
    )
  end

  it 'returns a fresh step array for the future Game#stock_round constructor' do
    expect(described_class.steps).not_to equal(described_class.steps)
    expect(described_class::STEPS).to be_frozen
  end
end
