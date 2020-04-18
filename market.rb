require 'pry'
require 'pry-byebug'
require 'mongo' #https://docs.mongodb.com/ruby-driver/current/
require './efficient_profit'

class Market
  attr_accessor :name, :assets, :profits, :risks, :correlations
  attr_accessor :mongo, :errors
  attr_reader :profit_hash

  def initialize(name, profits, risks, correlations)
    error_log('マーケット名が文字列ではありません') unless name.is_a?(String)
    return false if errors

    @name, @profits, @risks, @correlations = name.to_sym, profits, risks, correlations
    @mongo = get_mongo.use('dataset')

    @profit_hash = {}

    allocations = combinations
    pros = allocations.map{|allo| [profit(allo), allo]}.sort
    pros.map{|pro| pro[0]}.uniq.each{|idx|
      profit_hash[idx] = pros.select{|pro| pro[0] == idx}.map{|pro| pro[1]}
    }

    # efficient_profit = EfficientProfit.new(3.0, profit_hash[3.0], risks, correlations)
    # binding.pry

    mongo[name].drop
    profit_hash.each { |profit, allocations|
      efficient_profit = EfficientProfit.new(profit, allocations, risks, correlations)
      mongo[name].insert_one({
        profit: efficient_profit.profit,
        risk: efficient_profit.risk,
        allocation: efficient_profit.allocation
      })
    }

    mongo[name].insert_one({
      dataset: name,
      assets: assets,
      profits: profits,
      risks:risks,
      correlations: correlations
    })

    mongo[name].find.batch_size(1000).each{ |portfolio| puts portfolio }
  end




  private
  def combinations(size: profits.size, total: 100, step: 2)
    myself = 0
    comb_array = []

    if size == 2
      until myself > total
        comb_array << [myself, total - myself]
        myself = myself + step
      end
      return comb_array
    end

    until myself > total
      combs = combinations(size: size - 1, total: total - myself, step: step).map{|c| c.push(myself) }

      # １つ出来上がるたびに、利益率を計算して、小数第一位より細ければ、弾く（これで計算量とDBアクセスをぐっと減らす）
      if size == profits.size
        comb_array << combs.select{ |comb| valid_profit?(profit(comb)) }
        puts "progress #{myself} % #{"."*myself}"
      else
        comb_array << combs
      end

      myself = myself + step
    end

    return comb_array.flatten(1)
  end

  def valid_profit?(profit)
    profit.round(1) == profit && profit >= 3 && profit <= 7
  end

  def profit(allocation)
    [profits, allocation].transpose.map{|e| e.inject(:*)}.sum / 100
  end


  def get_mongo
    Mongo::Logger.logger.level = Logger::INFO
    Mongo::Client.new([ '127.0.0.1:27017' ]).with(user: 'root', password: 'root')
  end

  def error_log(str)
    caller_line = caller.first.split(":")[1]
    @errors = "#{__FILE__} : #{caller_line} : #{str}"
  end

end