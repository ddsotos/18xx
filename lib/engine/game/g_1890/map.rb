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
          'D9' => '宝塚',
          'D15' => '高槻',
          'D19' => '宇治',

          # E段
          'E10' => '伊丹',
          'E12' => '豊中',
          'E14' => '茨城・摂津',
          'E22' => '枚方',

          # F段
          'F1' => '姫路・山陽',
          'F3' => '明石',
          'F5' => '神戸',
          'F7' => '芦屋',
          'F9' => '西宮',
          'F11' => '尼崎',
          'F13' => '吹田',
          'F15' => '寝屋川',

          # G段
          'G12' => '大阪北',
          'G14' => '守口・門真',
          'G16' => '大東・四条畷',

          # H段
          'H11' => '大阪西',
          'H13' => '大阪東',
          'H15' => '東大阪',
          'H19' => '奈良',

          # I段
          'I12' => '大阪南',
          'I18' => '郡山',
          # J段
          'J11' => '堺',
          'J15' => '柏原',
          'J19' => '天理',

          # K段
          'K10' => '泉大津',
          'K18' => '桜井',
          'K20' => '伊勢・東海',

          # L段
          'L9' => '岸和田',

          # M段
          'M6' => '関西空港',
          'M8' => '泉佐野',
          'M14' => '高野山',

          # N段
          'N7' => '和歌山',
        }.freeze
#ラベルはKY 京都 KB 神戸 ON 大阪北
        HEXES = {
          white: {
            %w[D11 D13 D17 E2 I14 J13 K12 K14 L11 L13 L17] => '',
            %w[D15 E10 E12 F3 F7 F13 F15 H15 K18 L9 M8] => 'city=revenue:0',
            ['F11'] => 'city=revenue:0;label=Y',
            %w[D3 D7 I18 J19 K10] => 'town=revenue:0',
            %w[G16] => 'town=revenue:0;town=revenue:0',
            %w[A16 B15 C8 C16 E18 F17] => 'upgrade=cost:80,terrain:water',
            %w[B9 B11 B13 C4 C6 C10 C12 C14 E4 E6 E8 F17 G18 H17 I16 J17 K16 L15 M10 M12] => 'upgrade=cost:120,terrain:mountain',
            %w[C18 D9 F9] => 'city=revenue:0;upgrade=cost:80,terrain:water',
          },
          yellow: {
            ['B19'] => 'path=a:1,b:0',
            ['B17'] => 'city=revenue:40;city=revenue:40;city=revenue:40;'\
                       'upgrade=cost:80,terrain:water;path=a:0,b:_0;path=a:4,b:_1;path=a:5,b:_2;label=KY',
            ['E16'] => 'city=revenue:20,slots:1;path=a:0,b:_0;path=a:3,b:_0;',
            ['F5'] => 'city=revenue:30,slots:1;path=a:1,b:_0;path=a:2,b:_0;path=a:4,b:_0',
            ['G12'] => 'city=revenue:40,slots:2;upgrade=cost:80;path=a:2,b:_0;path=a:3,b:_0;label=ON',
            %w[E14 G14 J11] => 'city=revenue:0;city=revenue:0',
            ['I12'] => 'city=revenue:40,slots:2;upgrade=cost:80;path=a:0,b:_0;path=a:5,b:_0;label=Y',
            ['H13'] => 'city=revenue:40;city=revenue:40;upgrade=cost:80;path=a:3,b:_0;path=a:4,b:_1;label=OE',
            ['H11'] => 'city=revenue:30;upgrade=cost:80;path=a:3,b:_0;path=a:4,b:_0;label=OW',
            ['H19'] => 'city=revenue:40;city=revenue:40;upgrade=cost:80;path=a:0,b:_0;path=a:1,b:_1;path=a:3,b:_1',
            ['J15'] => 'city=revenue:20,slots:1;path=a:1,b:_0;path=a:4,b:_0;',
          },
          gray: {
            ['D5'] => 'city=revenue:20,slots:1;path=a:1,b:_0;path=a:4,b:_0;path=a:0,b:_0',
            ['G20'] => 'path=a:2,b:0',
            ['D19'] => 'city=revenue:20,slots:1;path=a:2,b:0;path=a:2,b:_0',
          },
          red: {
            ['F1'] => 'offboard=revenue:yellow_40|brown_50|diesel_70;path=a:3,b:_0;path=a:4,b:_0',
            ['B7'] => 'offboard=revenue:yellow_10|brown_20|diesel_30;path=a:4,b:_0;path=a:5,b:_0;path=a:0,b:_0',
            ['A14'] => 'offboard=revenue:yellow_10|brown_20|diesel_30;path=a:5,b:_0;path=a:0,b:_0',
            ['A20'] => 'offboard=revenue:yellow_30|brown_30|diesel_40;path=a:4,b:_0;path=a:5,b:_0;path=a:0,b:_0',
            ['B21'] => 'offboard=revenue:yellow_30|brown_30|diesel_40;path=a:1,b:_0',
            ['K20'] => 'offboard=revenue:yellow_20|brown_30|diesel_40;path=a:1,b:_0;path=a:2,b:_0',
            ['M6'] => 'offboard=revenue:yellow_0|brown_0|diesel_50;path=a:4,b:_0',
            ['M14'] => 'offboard=revenue:yellow_20|brown_20|diesel_30;path=a:1,b:_0;path=a:2,b:_0',
            ['N7'] => 'offboard=revenue:yellow_20|brown_30|diesel_40;path=a:3,b:_0',
          },
        }.freeze

        LAYOUT = :pointy
      end
    end
  end
end
