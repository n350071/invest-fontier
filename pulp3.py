# import pulp
# 自分でインストールした CBCソルバをPuLPで使用する
# https://qiita.com/nariaki3551/items/ea1117afb7f8ffbf7e90
# print(pulp.__path__)
# ['/Users/naoki/.pyenv/versions/3.8.0/lib/python3.8/site-packages/pulp']
# ln -s /usr/local/Cellar/CBC/2.10.3_1/bin/cbc /usr/local/bin/cbc

import pulp
# from pulp import *

ASSETS = ["日本国債", "先進国国債", "新興国国債"]
RETURNS = [0.3, 0.8, 4.2]
# RETURNS = [30, 80, 420]
RISKS = [2.02, 6.72, 13.73]
RELATIONS = [
  [1, -0.09, -0.18],
  [-0.09, 1, 0.75],
  [-0.18, 0.75, 1]
]
# RELATIONS = [
#   [100, -9, -18],
#   [-9, 100, 75],
#   [-18, 75, 100]
# ]

returns = {}
for i in ASSETS:
  returns[i] = RETURNS[ASSETS.index(i)]

risks = {}
for i in ASSETS:
  risks[i] = RISKS[ASSETS.index(i)]

relations = {}
for i in ASSETS:
  for j in ASSETS:
    relations[i,j] = RELATIONS[ASSETS.index(i)][ASSETS.index(j)]

print("相関係数 relations[i,j]: ")
for i in ASSETS:
    print("risks[{:}] = {:f},  ".format(i, risks[i]), end = "")
    print("returns[{:}] = {:f},  ".format(i, returns[i]), end = "")
    for j in ASSETS:
        print("relations[{:},{:}] = {:f},  ".format(i, j, relations[i,j]), end = "")
    print("")
print("")

# 数理最適化問題を定義
# LpProblem: https://coin-or.github.io/pulp/technical/pulp.html?highlight=lpproblem
# problem = pulp.LpProblem(sense=pulp.LpMaximize)
problem = pulp.LpProblem(sense=pulp.LpMinimize)

# 変数集合
# pulp.LpVariable: https://coin-or.github.io/pulp/technical/pulp.html?highlight=lpvariable#pulp.LpVariable
x = {}
for i in ASSETS:
  x[i] = pulp.LpVariable("x({:})".format(i), 0, 100)

################# 目的関数 #################
problem += sum(relations[i,j] * x[i] * x[j] for i in ASSETS for j in ASSETS)


################# 制約条件 #################
# 各資産割合の合計は１00
problem += sum(x[i] for i in ASSETS) == 100
# 分散は４（リスクは２）
# problem += sum(relations[i,j] * risks[i] * risks[j] * x[i] * x[j] for i in ASSETS for j in ASSETS) == 4
# 期待値
problem += pulp.lpSum(returns[i] * x[i] for i in ASSETS) == 420

################# COIN CBCソルバ #################
solver = pulp.COIN_CMD()
result_status = problem.solve(solver)

# （解が得られていれば）目的関数値や解を表示
print("計算結果")
print("********")
# print("最適性 = {:}, 目的関数値 = {:}, 計算時間 = {:} (秒)"
#       .format(pulp.LpStatus[result_status], pulp.value(problem.objective),
#               time_stop - time_start))
print("最適性 = {:}, 目的関数値 = {:}"
      .format(pulp.LpStatus[result_status], pulp.value(problem.objective)))

print("解 x[i,j]: ")
for i in ASSETS:
    print("{:} = {:},  "
            .format(x[i].name, x[i].value()), end="")
    print("")
print("********")