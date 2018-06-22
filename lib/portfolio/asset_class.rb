module Portfolio
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
end
