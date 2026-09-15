# frozen_string_literal: true

require './spec/spec_helper'

describe Engine::Game::GRotLA::Round::Stock do
  let(:price_class) { Struct.new(:price) }

  let(:corporation_class) do
    Class.new do
      include Comparable

      attr_reader :name, :type
      attr_accessor :share_price

      def initialize(name:, type:, floated:, price:)
        @name = name
        @type = type
        @floated = floated
        @share_price = price
      end

      def floated?
        @floated
      end

      def <=>(other)
        name <=> other.name
      end
    end
  end

  let(:game_class) do
    pool_share_drop = :none

    Class.new do
      const_set(:POOL_SHARE_DROP, pool_share_drop)

      attr_reader :corporations, :stock_market, :movements

      def initialize(corporations, next_prices)
        @corporations = corporations
        @next_prices = next_prices
        @movements = []
        game = self
        @stock_market = Object.new
        @stock_market.define_singleton_method(:move_up) do |corporation|
          corporation.share_price = game.next_price(corporation)
        end
      end

      def sold_out?(_corporation)
        true
      end

      def sold_out_increase?(_corporation)
        true
      end

      def sold_out_stock_movement(corporation)
        stock_market.move_up(corporation)
      end

      def log_share_price(corporation, old_price)
        @movements << [corporation.name, old_price.price, corporation.share_price.price]
      end

      def next_price(corporation)
        @next_prices.fetch(corporation)
      end
    end
  end

  it 'applies a sold-out increase to floated minor and major companies' do
    price_70 = price_class.new(70)
    price_80 = price_class.new(80)
    minor = corporation_class.new(name: 'Minor', type: :minor, floated: true, price: price_70)
    major = corporation_class.new(name: 'Major', type: :major, floated: true, price: price_70)
    unstarted = corporation_class.new(name: 'Unstarted', type: :minor, floated: false, price: price_70)
    game = game_class.new([minor, major, unstarted], { minor => price_80, major => price_80 })
    round = described_class.allocate
    round.instance_variable_set(:@game, game)

    round.send(:finish_round)

    expect(minor.share_price.price).to eq(80)
    expect(major.share_price.price).to eq(80)
    expect(unstarted.share_price.price).to eq(70)
    expect(game.movements).to contain_exactly(['Minor', 70, 80], ['Major', 70, 80])
  end
end
