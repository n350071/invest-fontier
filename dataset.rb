require 'pry'
require 'pry-byebug'
require 'mongo' #https://docs.mongodb.com/ruby-driver/current/
require 'bigdecimal'

class Dataset
  attr_accessor :name, :asset_names, :returns, :risks, :correlations
  attr_accessor :step, :mongo, :errors

  def initialize(name: nil, step: 5)
    @name = name.to_sym
    @mongo = get_mongo
    @step = step
  end

  def create
    return false unless valid_to_create?

    portfolio_patterns = combinations(size: returns.count, total: 100, step: step)
    portfolio_patterns.each_with_index{ |ratios, idx|
      puts "#{idx} / #{portfolio_patterns.count}"
      mongo[name].insert_one({id: idx, ratios: ratios})
    }

    mongo[name].find.batch_size(1000).each{ |portfolio|
      puts "id: #{portfolio[:id]} / #{portfolio_patterns.count}, ratios:#{portfolio[:ratios]} "

      p_return = portfolio_return(portfolio[:ratios])
      p_risk = portfolio_risk(portfolio[:ratios])
      next unless p_risk
      mongo[name].find(id: portfolio[:id])
        .find_one_and_update( '$set' => {
           return: p_return,
           risk: p_risk,
           sharp_ratio: p_return / p_risk
        })
    }

    mongo[name].insert_one({
      asset_names: asset_names,
      returns: returns,
      risks: risks,
      correlations: correlations
      })

    true
  end

  def show
    mongo[name].find.batch_size(1000).each{ |portfolio| puts portfolio }
  end

  def destroy
    return unless name
    mongo[name].drop
  end

  private
  def portfolio_return(ratios)
    [returns, ratios].transpose.map{|e| e.inject(:*)}.sum / 100
  end

  def portfolio_risk(ratios)
    Math.sqrt(portfolio_variance(ratios)) / 100
  end

  def portfolio_variance(ratios)
    all_risks = []
    correlations.each.with_index(0){
      |rels, i| rels.each.with_index(0){
        |rel, j| all_risks << risks[i] * risks[j] * rel * ratios[i] * ratios[j]
      }
    }
    all_risks.sum
  end

  def valid_to_create?
    error_log(str: 'すでにコレクションが存在します') if mongo.database.collection_names.include?(name.to_s)
    error_log(str: 'サイズが小さすぎます') unless returns.count >= 2
    error_log(str: 'リターンとリスクのサイズが違います') unless returns.count == risks.count
    error_log(str: 'リターンと相関係数のサイズが違います') unless returns.count == correlations.count
    error_log(str: 'リターンと資産名称のサイズが違います') unless returns.count == asset_names.count
    error_log(str: '相関係数に有効でない数字が入っています') unless valid_correlations?
    error_log(str: '相関係数のサイズが違います') unless valid_correlations_dimension?
    return false if errors

    true
  end

  def valid_correlations?
    correlations.all? { |rels|
      rels.all? { |rel|
        rel >= -1 && rel <= 1
      }
    }
  end

  def valid_correlations_dimension?
    ret = []
    correlations.each.with_index(1){|rels, idx|
      ret << (rels.count == idx)
    }
    ret.all?(true)
  end

  def combinations(size: 8, total: 100, step: 5)
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
      comb_array << combinations(size: size - 1, total: total - myself, step: step).map{|c| c.push(myself) }

      myself = myself + step
    end

    return comb_array.flatten(1)
  end

  def get_mongo
    Mongo::Logger.logger.level = Logger::INFO
    Mongo::Client.new([ '127.0.0.1:27017' ]).with(user: 'root', password: 'root').use('dataset')
  end

  def error_log(str: '')
    caller_line = caller.first.split(":")[1]
    @errors = "#{__FILE__} : #{caller_line} : #{str}"
  end
end