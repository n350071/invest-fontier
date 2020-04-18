require 'pry'
require 'pry-byebug'
require 'mongo' #https://docs.mongodb.com/ruby-driver/current/

class EfficientProfit
  attr_accessor :profit, :allocations, :risks, :correlations
  attr_accessor :risk, :allocation

  def initialize(profit, allocations, risks, correlations)
    @profit, @allocations = profit, allocations
    @risks, @correlations = risks, correlations

    risk_map = allocations.map{ |allo| portfolio_risk(allo) }
    @risk = risk_map.min
    @allocation = allocations[risk_map.find_index(risk)]
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


end
