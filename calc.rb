require 'pry'
require 'pry-byebug'
require 'mongo' #https://docs.mongodb.com/ruby-driver/current/
require './dataset'

data = Dataset.new(name: 'jp_morgan_2020_10', step: 10)
data.asset_names = %i(
  日本国債
  先進国国債
  新興国国債
  日本大型株式
  米国大型株式
  先進国株式
  新興国株式
  米国REIT
)
data.returns = [0.3, 0.8, 4.2, 5.5, 3.9, 4.5, 7.5, 4.3]
data.risks = [2.02, 6.72, 13.73, 18.10, 18.73, 19.39, 23.11, 17.47]
data.correlations = [[1],
                      [-0.09, 1],
                      [-0.18, 0.75, 1],
                      [-0.34, 0.59, 0.70, 1],
                      [-0.34, 0.87, 0.73, 0.81, 1],
                      [-0.33, 0.69, 0.79, 0.83, 0.98, 1],
                      [-0.29, 0.60, 0.85, 0.75, 0.80, 0.87, 1],
                      [-0.11, 0.51, 0.63, 0.62, 0.77, 0.76, 0.62, 1]
                    ]

# data = Dataset.new(name: 'test')
# data.asset_names = %i(
#   日本国債
#   先進国国債
#   新興国国債
# )
# data.returns = [0.3, 0.8, 4.2]
# data.risks = [2.02, 6.72, 13.73]
# data.correlations = [[1],
#                       [-0.09, 1],
#                       [-0.18, 0.75, 1]
#                     ]

if data.present?
  data.show
  return
end

if data.create
else
  puts data.errors
  return
end

data.show

# 1. リターンを計算して、4.60, 4.70, などピッタリ0.1刻みのものだけを保存する。（←ここの件数が高々１万件程度であれば、現実的だろう）
# 2. 各リターンについて、最大のシャープレシオとなるものを選ぶ