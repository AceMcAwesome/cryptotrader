trading = require 'trading'
params = require 'params'
ds = require 'datasources'
talib = require 'talib' # import technical indicators library (https://cryptotrader.org/talib)

#ds.add 'poloniex', 'eth_btc', '1h'
#ds.add 'poloniex', 'ltc_btc', '1h'
ds.add 'gdax', 'eth_btc', '1h'
ds.add 'gdax', 'ltc_btc', '1h'

# This method is called for each tick
handle: ->
    numPairs = @data.instruments.length-1
    primary = @data.instruments[0]
    storage.short0 ?= 0
    storage.long0 ?= 0
    storage.short1 ?= 0
    storage.long1 ?= 0
    storage.short2 ?= 0
    storage.long2 ?= 0
    storage.last_diff1 ?= 0
    storage.last_diff2 ?= 0
    storage.last_ltc_eth_diff ?= 0
    #for i in [1..@data.instruments.length-1] # skip primary instrument as we do no trade with it
    #    ins = @data.instruments[i]
    #    if ins.price
    #        total += @portfolio.positions[ins.asset()].amount * ins.price
    #debug "Total portfolio: #{total} #{primary.base().toUpperCase()}"
    ins0 = @data.instruments[0]
    ins1 = @data.instruments[1]
    ins2 = @data.instruments[2]
    plot
        eth_btc: ins1.price
        ltc_btc: ins2.price
    short1 = ins1.ema(20)
    long1 = ins1.ema(42)
    diff1 = 100 * (short1 - long1) / ((short1 + long1) / 2)
    short2 = ins2.ema(20)
    long2 = ins2.ema(42)
    diff2 = 100 * (short2 - long2) / ((short2 + long2) / 2)
    ltc_eth_short = short2 / short1
    ltc_eth_long = long2 / long1
    ltc_eth_diff = 100 * (ltc_eth_short - ltc_eth_long) / ((ltc_eth_short + ltc_eth_long) / 2)
    #debug "diff1 is #{diff1}"
    debug "diff2 is #{diff2}"
    debug "ltc_eth_diff is #{ltc_eth_diff}"
    my_btc = @portfolio.positions[ins1.base()].amount
    my_eth = @portfolio.positions[ins1.asset()].amount
    my_ltc = @portfolio.positions[ins2.asset()].amount
    #debug "my_btc is #{my_btc}"
    #debug "my_eth is #{my_eth}"
    #debug "my_ltc is #{my_ltc}"

    if diff1 > 0.25 and storage.last_diff1 < 0.25
        if my_btc > 0.0001
            trading.buy ins1, 'limit', my_btc / 1.02 / ins1.price, ins1.price
            debug "my_btc is #{@portfolio.positions[ins1.base()].amount}"
            debug "my_eth is #{@portfolio.positions[ins1.asset()].amount}"
            debug "my_ltc is #{@portfolio.positions[ins2.asset()].amount}"
            
    if diff1 < -0.25 and storage.last_diff1 > -0.25
        if my_eth > 0.0001
            trading.sell ins1, 'limit'
            debug "my_btc is #{@portfolio.positions[ins1.base()].amount}"
            debug "my_eth is #{@portfolio.positions[ins1.asset()].amount}"
            debug "my_ltc is #{@portfolio.positions[ins2.asset()].amount}"
            
    if diff2 > 0.26 and storage.last_diff1 < 0.26
        if my_btc > 0.0001
            trading.buy ins2, 'limit', my_btc / 1.02 / ins2.price, ins2.price
            debug "my_btc is #{@portfolio.positions[ins1.base()].amount}"
            debug "my_eth is #{@portfolio.positions[ins1.asset()].amount}"
            debug "my_ltc is #{@portfolio.positions[ins2.asset()].amount}"
            
    if diff2 < -0.25 and storage.last_diff2 > -0.25
        if my_ltc > 0.0001
            trading.sell ins2, 'limit'
            debug "my_btc is #{@portfolio.positions[ins1.base()].amount}"
            debug "my_eth is #{@portfolio.positions[ins1.asset()].amount}"
            debug "my_ltc is #{@portfolio.positions[ins2.asset()].amount}"
            
    if ltc_eth_diff > 0.25 and storage.last_ltc_eth_diff < 0.25
        debug "EXECUTING A SELL-AND-BUY"
        if my_eth > 0.0001
            trading.sell ins1, 'limit'
            trading.buy ins2, 'limit', my_btc / 1.02 / ins2.price, ins2.price
            debug "my_btc is #{@portfolio.positions[ins1.base()].amount}"
            debug "my_eth is #{@portfolio.positions[ins1.asset()].amount}"
            debug "my_ltc is #{@portfolio.positions[ins2.asset()].amount}"
            
    if ltc_eth_diff < -0.25 and storage.last_ltc_eth_diff > -0.25
        if my_ltc > 0.0001
            debug "EXECUTING A BUY-AND-SELL"
            trading.sell ins2, 'limit'
            trading.buy ins1, 'limit', my_btc / 1.02 / ins2.price, ins2.price
            debug "my_btc is #{@portfolio.positions[ins1.base()].amount}"
            debug "my_eth is #{@portfolio.positions[ins1.asset()].amount}"
            debug "my_ltc is #{@portfolio.positions[ins2.asset()].amount}"


    
    storage.last_diff1 = diff1
    storage.last_diff2 = diff2
    storage.last_ltc_eth_diff = ltc_eth_diff