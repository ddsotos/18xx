# frozen_string_literal: true

module Engine
  module Game
    module G1890
      module Entities
        COMPANIES = [
          {
            name: '有馬鉄道',
            value: 20,
            revenue: 5,
            desc: "配置制限:有馬(D7) \n 企業に売られたら有馬にタイル配置",
            sym: '有電',
            abilities: [{ type: 'blocks_hexes', owner_type: 'player', hexes: ['D7'] },
                        {
                          type: 'tile_lay',
                          hexes: ['D7'],
                          tiles: %w[3 4 58],
                          when: 'sold',
                          owner_type: 'corporation',
                          count: 1,
                        }],
            color: nil,
          },
          {
            name: '神戸市電',
            value: 40,
            revenue: 10,
            desc: '配置制限:神戸(F5)',
            sym: '神電',
            abilities: [{ type: 'blocks_hexes', owner_type: 'player', hexes: ['F5'] }],
            color: nil,
          },
          {
            name: '阪堺電鉄',#TODO 4フェイズにプレイヤー持ちでも封鎖が消えるかどうか
            value: 70,
            revenue: 15,
            desc: '配置制限:堺(J11)大阪南(I10) \n 第4フェイズ(5列車購入時)に閉鎖しない　ただし収入は5になり、売却できず、株券枚数制限に含み続ける',
            sym: '堺電',
            abilities: [{ type: 'blocks_hexes', owner_type: 'player', remove: '5',hexes: %w[J11 I10] },
                        { type: 'close', on_phase: 'never'},
                        {
                          type: 'revenue_change',
                          revenue: 5,
                          on_phase: '5',
                        }],
            color: nil,
          },
          {
            name: '阪神国道軌道',
            value: 110,
            revenue: 20,
            desc: '配置制限なし　阪神電鉄の株券1株が付属',
            sym: '阪国',
            abilities: [
              { type: 'shares', shares: 'HS_1' }
            ],
            color: nil,
          },
          {
            name: '京津鉄道',
            value: 160,
            revenue: 25,
            desc: '配置制限:京都(B17)京都の東(B19) \n 京阪電鉄の株券1株が付属',
            sym: '京津',
            abilities: [
              { type: 'blocks_hexes', owner_type: 'player', hexes: %w[J11 I10] },          
              { type: 'shares', shares: 'KH_1' }
            ],
            color: nil,
          },
          {
            name: '大阪市電',#TODO 大阪地下鉄の最初の手番がくれば、大阪市内の3ヘックスへのタイルの置き換えは、自由になるものとします。と、大阪市電は、プレーヤーに購入された時点で、額面価格が¥0 に変更されます。
            value: 220,
            revenue: 40,
            desc: '配置制限:大阪北(G12)大阪西(H11)大阪東(H13)  '\
                  '購入プレーヤーは大阪地下鉄の株価を設定し、社長株を受け取ります。'\
                  '大阪地下鉄が設立されても、列車を購入しなければ、大阪市電は閉鎖されず、大阪地下鉄は、配当を受け続けることができます。'\
                  'しかし、大阪地下鉄は、運営ラウンドの自社の手番で無配を繰り返すため、株価は下がり続けます。'\
                  '大阪地下鉄の最初の手番がくれば、大阪市内の3ヘックスへのタイルの置き換えは、自由になるものとします。'\
                  '大阪地下鉄が列車を購入すると大阪市電は閉鎖されます。この個人会社は、公共会社が購入することが出来ません。',
            abilities: [{ type: 'blocks_hexes', owner_type: 'player', hexes: %w[G12 H11 H13] },
                        { type: 'close', when: 'bought_train', corporation: 'HT' },
                        { type: 'no_buy' },
                        { type: 'shares', shares: 'HT_0' }],
            sym: '市電',
            color: nil,
          },
          {
            name: 'Uno-Takamatsu Ferry',
            value: 150,
            revenue: 30,
            desc: 'Does not close while owned by a player. If owned by a player '\
                  'when the first 5-train is purchased it may no longer be sold '\
                  'to a public company and the revenue is increased to 50.',
            sym: 'UTF',
            min_players: 4,
            abilities: [{ type: 'close', on_phase: 'never', owner_type: 'player' },
                        {
                          type: 'revenue_change',
                          revenue: 50,
                          on_phase: '5',
                          owner_type: 'player',
                        }],
            color: nil,
          },
        ].freeze

        CORPORATIONS = [
          {
            float_percent: 50,
            sym: 'AR',
            name: 'Awa Railroad',
            logo: '1889/AR',
            simple_logo: '1889/AR.alt',
            tokens: [0, 40],
            coordinates: 'K8',
            color: '#37383a',
          },
          {
            float_percent: 50,
            sym: 'IR',
            name: 'Iyo Railway',
            logo: '1889/IR',
            simple_logo: '1889/IR.alt',
            tokens: [0, 40],
            coordinates: 'E2',
            color: '#f48221',
          },
          {
            float_percent: 50,
            sym: 'SR',
            name: 'Sanuki Railway',
            logo: '1889/SR',
            simple_logo: '1889/SR.alt',
            tokens: [0, 40],
            coordinates: 'I2',
            color: '#76a042',
          },
          {
            float_percent: 50,
            sym: 'KO',
            name: 'Takamatsu & Kotohira Electric Railway',
            logo: '1889/KO',
            simple_logo: '1889/KO.alt',
            tokens: [0, 40],
            coordinates: 'K4',
            color: '#d81e3e',
          },
          {
            float_percent: 50,
            sym: 'TR',
            name: 'Tosa Electric Railway',
            logo: '1889/TR',
            simple_logo: '1889/TR.alt',
            tokens: [0, 40, 40],
            coordinates: 'F9',
            color: '#00a993',
          },
          {
            float_percent: 50,
            sym: 'KU',
            name: 'Tosa Kuroshio Railway',
            logo: '1889/KU',
            simple_logo: '1889/KU.alt',
            tokens: [0],
            coordinates: 'C10',
            color: '#0189d1',
          },
          {
            float_percent: 50,
            sym: 'UR',
            name: 'Uwajima Railway',
            logo: '1889/UR',
            simple_logo: '1889/UR.alt',
            tokens: [0, 40, 40],
            coordinates: 'B7',
            color: '#6f533e',
          },
        ].freeze
      end
    end
  end
end
