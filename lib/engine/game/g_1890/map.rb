# frozen_string_literal: true

module Engine
  module Game
    module G1890
      module Map
        TILES = {
          '1' => 1,
          '2' => 1,
          '3' => 2,
          '6' => 2,
          '7' => 4,
          '8' => 8,
          '9' => 9,
          '12' => 2,
          '14' => 2,
          '15' => 2,
          '16' => 2,
          '18' => 1,
          '19' => 2,
          '20' => 2,
          '23' => 3,
          '24' => 3,
          '25' => 3,
          '26' => 2,
          '27' => 2,
          '28' => 2,
          '29' => 2,
          '39' => 1,
          '40' => 1,
          '41' => 2,
          '42' => 2,
          '43' => 1,
          '44' => 2,
          '45' => 2,
          '46' => 2,
          '47' => 2,
          '56' => 1,
          '57' => 4,
          '58' => 3,
          '63' => 3,
          '74' => 1,
          '78' => 3,
          '202' => 1,
          '205' => 1,
          '206' => 1,
          '208' => 1,
          '210' => 1,
          '211' => 1,
          '217' => 1,
        }.freeze

        LOCATION_NAMES = {
          # A段 (最上段：山陰・丹波)
          'A14' => '山陰・丹波',
          'A20' => '中部',
          # B段
          'B7' => '山陰・丹波',
          'B17' => '京都',
          'B21' => '東海',

          # C段
          'C18' => '伏見',

          # D段
          'D3' => '三木',
          'D5' => '谷上',
          'D7' => '有馬',
          'D11' => '宝塚',
          'D17' => '高槻',
          'D21' => '宇治',

          # E段
          'E12' => '伊丹',
          'E14' => '豊中',
          'E14' => '茨城・摂津',
          'E22' => '枚方',

          # F段
          'F1' => '姫路・山陽',
          'F3' => '明石',
          'F5' => '神戸',
          'F7' => '芦屋',
          'F9' => '西宮',
          'F18' => '高槻',

          # G段
          'G8' => '芦屋',
          'G20' => '摂津',

          # H段
          'H9' => '西宮',
          'H16' => '吹田',
          'H22' => '枚方',

          # I段
          'I14' => '尼崎',
          'I20' => '寝屋川',
          # J段
          'J14' => '大阪北',
          'J18' => '守口',
          'J22' => '四条畷',

          # K段
          'K12' => '大阪西',
          'K14' => '堺',
          'K16' => '大阪東',
          'K18' => '門真',
          'K20' => '東大阪',
          'K26' => '郡山',

          # L段
          'L12' => '泉大津',
          'L14' => '大阪南',
          'L16' => '柏原',
          'L26' => '天理',

          # M段
          'M10' => '岸和田',
          'M16' => '高野山',
          'M24' => '桜井',

          # N段
          'N8' => '泉佐野',
          'N24' => '伊勢・東海',

          # O段
          'O6' => '関西空港',

          # P段
          'P8' => '和歌山'
        }.freeze

        HEXES = {
          white: {
            %w[D3 H3 J3 B5 C8 E8 I8 D9 I10] => '',
            %w[F3 G4 H7 A10 J11 G12 E2 I2 K8 C10] => 'city=revenue:0',
            ['J5'] => 'town=revenue:0',
            %w[B11 G10 I12 J9] => 'town=revenue:0;icon=image:port',
            ['K6'] => 'upgrade=cost:80,terrain:water',
            %w[H5 I6] => 'upgrade=cost:80,terrain:water|mountain',
            %w[E4 D5 F5 C6 E6 G6 D7 F7 A8 G8 B9 H9 H11 H13] => 'upgrade=cost:80,terrain:mountain',
            ['I4'] => 'city=revenue:0;label=H;upgrade=cost:80',
          },
          yellow: {
            ['C4'] => 'city=revenue:20;path=a:2,b:_0',
            ['K4'] => 'city=revenue:30;path=a:0,b:_0;path=a:1,b:_0;path=a:2,b:_0;label=T',
          },
          gray: {
            ['B7'] => 'city=revenue:40,slots:2;path=a:1,b:_0;path=a:3,b:_0;path=a:5,b:_0',
            ['B3'] => 'town=revenue:20;path=a:0,b:_0;path=a:_0,b:5',
            ['G14'] => 'town=revenue:20;path=a:3,b:_0;path=a:_0,b:4',
            ['J7'] => 'path=a:1,b:5',
          },
          red: {
            ['F1'] => 'offboard=revenue:yellow_40|brown_50|diesel_70;path=a:3,b:_0;path=a:4,b:_0',
            ['B7'] => 'offboard=revenue:yellow_20|brown_40|diesel_80;path=a:4,b:_0;path=a:5,b:_0;path=a:6,b:_0',
            ['A14'] => 'offboard=revenue:yellow_20|brown_40|diesel_80;path=a:4,b:_0;path=a:5,b:_0;path=a:6,b:_0',
            ['L7'] => 'offboard=revenue:yellow_20|brown_40|diesel_80;path=a:1,b:_0;path=a:2,b:_0',
          },
          green: {
            ['F9'] => 'city=revenue:30,slots:2;path=a:2,b:_0;path=a:3,b:_0;'\
                      'path=a:4,b:_0;path=a:5,b:_0;label=K;upgrade=cost:80',
          },
        }.freeze

        LAYOUT = :pointy
      end
    end
  end
end
