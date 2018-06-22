require 'portfolio'
require 'gnuplot'

def plot
  ef = Portfolio::EfficientFrontier.new([
    Portfolio::CasinoGame.new(name: "ルーレット", winrate: 1/38.0, equity: 36),
    Portfolio::CasinoGame.new(name: "バカラ", winrate: 0.48, equity: 2),
    Portfolio::CasinoGame.new(name: "ポーカー", winrate: 0.05, equity: 25),
    Portfolio::CasinoGame.new(name: "スロット", winrate: 0.001, equity: 999),
    Portfolio::CasinoGame.new(name: "預金", winrate: 1.0, equity: 1.0),
  ])
  p "mean: #{ef.asset_classes.map(&:mean)}"
  p "equity: #{ef.asset_classes.map(&:equity)}"
  p "variance: #{ef.asset_classes.map(&:variance)}"
  p "histdata: #{ef.asset_classes.map { |ac| 6.times.map { |i| ac.histdata[10 ** i - 1] } }}"

  Gnuplot.open do |gp|
    Gnuplot::Plot.new(gp) do |plot|
      plot.xlabel "variance"
      plot.ylabel "equity"

      variance_range = ef.variance_range
      equity_range = ef.equity_range

      target_equity = (equity_range.min + equity_range.max) / 2
      p "target_equity: #{target_equity}"
      ef.optimum_allotment(target_equity).each do |ac, rate|
        p "#{ac.name}: #{rate}"
      end

      # plot.xrange "[#{variance_range.min * 0.5}:#{variance_range.max * 1.2}]"
      # plot.yrange "[#{equity_range.min * 0.5}:#{equity_range.max * 1.2}]"
      plot.data << Gnuplot::DataSet.new([ef.asset_classes.map(&:variance), ef.asset_classes.map(&:equity)]) do |ds|
        ds.title = "asset classes"
        ds.with = "points pointtype 6"
      end
      list = equity_range.step((equity_range.max - equity_range.min) * 0.1).map do |e|
        [ef.expected_variance(e), e]
      end
      data = list[0].zip(*list[1..-1])
      plot.data << Gnuplot::DataSet.new(data) do |ds|
        ds.title = "efficient frontier"
        ds.with = "lp"
      end
    end
    gets
  end
end
