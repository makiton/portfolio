require "portfolio/version"

module Portfolio
  class EfficientFrontier
    attr_reader :asset_classes

    def initialize(asset_classes = [])
      @asset_classes = asset_classes
      calc_coefficients
    end

    def variance_range
      list = self.asset_classes.map(&:variance)
      (list.min..list.max)
    end

    def equity_range
      list = self.asset_classes.map(&:equity)
      (list.min..list.max)
    end

    def expected_variance(expected_equity)
      (@gamma * expected_equity ** 2 - 2 * @alpha * expected_equity + @beta) / @delta
    end

    def optimum_allotment(expected_equity)
      @optimum_allotment ||= asset_classes.map.with_index { |ac, i|
        member1 = member2 = 0
        asset_classes.each_with_index { |ac2, j|
          member1 += covariance_matrix[i, j] * (@gamma * ac2.equity - @alpha)
          member2 += covariance_matrix[i, j] * (@beta - @alpha * ac2.equity)
        }
        [ac, (expected_equity * member1 + member2)/ @delta]
      }.to_h
    end

    def calc_coefficients
      @alpha = 0
      @beta = 0
      @gamma = 0
      asset_classes.each_with_index { |ac1, i|
        asset_classes.each_with_index { |ac2, j|
          @alpha += covariance_matrix[i, j] * ac2.equity
          @beta += covariance_matrix[i, j] * ac1.equity * ac2.equity
          @gamma += covariance_matrix[i, j]
        }
      }
      @delta = @beta * @gamma - @alpha ** 2
      [@alpha, @beta, @gamma, @delta]
    end

    def covariance_matrix
      @covariance_matrix ||= Matrix[
        *asset_classes.map { |ac1|
          asset_classes.map { |ac2|
            if ac1 == ac2
              ac1.variance
            else
              ac1.covariance(ac2)
            end
          }
        }
      ].inv
    end
  end

  class AssetClass
    attr_accessor :name
    attr_reader :histdata, :equity, :variance, :mean

    def initialize(name:, histdata:)
      @name = name
      @histdata = histdata
    end

    def mean
      @mean ||= histdata.sum.to_f / histdata.count
    end

    def equity
      mean / histdata.first
    end

    def variance
      @variance ||= histdata.map { |d| (d - mean) ** 2 }.sum / histdata.count
    end

    def covariance(another_class)
      histdata.each_with_index { |d, i|
        (d - mean) * (another_class.histdata[i] - another_class.mean)
      }.sum.to_f / histdata.count
    end
  end

  class CasinoGame < AssetClass
    TRIALS = 100000

    def initialize(name:, winrate:, equity:)
      cur = 10000
      histdata = TRIALS.times.map {
        if rand <= winrate
          cur += equity - 1
        else
          cur -= 1
        end
      }
      super(name: name, histdata: histdata)
    end
  end
end
