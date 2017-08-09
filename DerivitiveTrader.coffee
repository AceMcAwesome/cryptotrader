trading = require 'trading' # import core trading module
talib = require 'talib' # import technical indicators library 

average =(my_instrument, average_length) ->
    n = my_instrument.length
    sum = 0
    avg_counter = average_length
    while avg_counter > 0
        sum = sum + my_instrument[n-avg_counter]
        avg_counter = avg_counter - 1
    avg = sum / average_length
    return(avg);

calc_der_of_array =(my_array) ->
    my_der_array = (0 for [1..500])
    n = my_array.length - 1
    while n > 200
        my_der_array[n] = 100*(my_array[n] - my_array[n-1]) / ((my_array[n] + my_array[n-1])/2)
        n = n - 1
    return(my_der_array);

calc_double_der_of_array =(my_array) ->
    my_der_array = (0 for [1..500])
    n = my_array.length - 1
    while n > 200
        my_der_array[n] = my_array[n] - my_array[n-1]
        n = n - 1
    return(my_der_array);

smooth_array =(my_array,kernel) ->
    my_smoothed_array = (0 for [1..500])
    n = my_array.length - 1
    while n > 200
        my_smoothed_array[n] = average(my_array[0..n],kernel)
        n = n - 1
    return(my_smoothed_array);

init: ->
    @context.buy_treshold = 25
    @context.sell_treshold = 25
    setPlotOptions
    der:
        color: 'blue'
    dder:
        color: 'orange'
    der_differential:
        color: 'black'
    der_diff_diff:
        color: 'red'
    zero_line:
        color: 'gray'

# This method is called for each tick
handle: ->
    # data object provides access to market data
    instrument = @data.instruments[0]
    average_5 = average(instrument.close,5)
    n = instrument.close.length
    storage.last_diff ?= 0
    storage.last_average_5 ?= 0
    storage.first_price ?= instrument.price
    storage.first_price_index ?= 0
    storage.der_differential ?= 0
    storage.last_der_diff_diff ?= 0
    short = instrument.ema(5)
    long = instrument.ema(21)
    #very_long = instrument.ema(300)
    my_index = 5 # default is 15

    der_array = calc_der_of_array(instrument.close)
    der_average_15 = average(der_array,my_index)
    der_average_15_norm = der_average_15 * storage.first_price
    smoothed_der = smooth_array(der_array,my_index)
    #smoothed_der_average_100 = average(smoothed_der,100)
    dder_array = calc_double_der_of_array(smoothed_der)
    dder_average_15 = average(dder_array,my_index)
    dder_average_15_norm = dder_average_15 * storage.first_price * 10
    #der_differential = (dder_average_15_norm - der_average_15_norm)
    der_differential = (dder_average_15 - der_average_15)
    der_differential_norm = 100*der_differential/storage.first_price
    der_diff_diff = der_differential - storage.last_der_differential
    debug "instrument.price is: #{instrument.price}"
    debug "der_average_15 is: #{der_average_15}"
    debug "dder_average_15 is: #{dder_average_15}"
    debug "der_differential is: #{der_differential}"
    debug "der_diff_diff is: #{der_diff_diff}"
    debug "storage.last_der_diff_diff is: #{storage.last_der_diff_diff}"
    plot
        #short: short
        #long: long
        #der: der_average_15/storage.first_price
        #dder: (dder_average_15/storage.first_price)/storage.first_price
        der: der_average_15/30 * storage.first_price + storage.first_price #* storage.first_price)
        dder: dder_average_15/30 * storage.first_price  + storage.first_price #* storage.first_price
        zero_line: storage.first_price
        der_differential: der_differential/30 * storage.first_price + storage.first_price
        der_diff_diff: der_diff_diff/30 * storage.first_price + storage.first_price
    diff = 100 * (short - long) / ((short + long) / 2)
    #der = instrument.price - storage.last_price
    #der_5 = average(instrument.close,5)

    #if der_differential_norm > @context.buy_treshold # and storage.last_diff < @context.buy_treshold
    if der_diff_diff < 0 and storage.last_der_diff_diff > 0 and der_differential > 0.3
        if @portfolio.positions[instrument.base()].amount > 0
            trading.buy instrument
    else
        #if der_differential_norm < -@context.sell_treshold # and storage.last_diff > -@context.sell_treshold
        if der_diff_diff > 0 and storage.last_der_diff_diff < 0 and der_differential < -0.3
            if @portfolio.positions[instrument.asset()].amount > 0
                trading.sell instrument

    storage.last_average_5 = average_5
    storage.last_price = instrument.price
    #storage.last_der = der
    storage.last_der_differential = der_differential
    storage.last_der_diff_diff = der_diff_diff

    if storage.first_price_index == 0
        storage.first_price = instrument.price
        storage.first_price_index = 1 