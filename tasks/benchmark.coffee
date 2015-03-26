Bacon = require 'baconjs'
Promise = require 'bluebird'
http = require('../src/http')(Promise)

stats = require 'simple-statistics'

###
(f: () -> Promise) -> milliseconds
###
time = (f) ->
  timestamp = +new Date
  Promise.resolve(f()).then ->
    (+new Date)-timestamp

module.exports = (grunt) ->

  benchmark = (f, concurrency, total) -> ->
    grunt.log.ok "Running benchmark..."
    new Promise (resolve) ->
      Bacon.fromArray(i for i in [0..total])
        .flatMapWithConcurrencyLimit(concurrency, (i) ->
          Bacon.fromPromise time(f)
        )
        .fold([], (list, time) ->
          process.stdout.write '.'
          list.push time
          list
        )
        .onValue (times) ->
          console.log ""
          grunt.log.ok "Execution times (milliseconds)"
          console.log """
          Minimum:       #{~~stats.min(times)}
          10% quantile:  #{~~stats.quantile(times, 0.1)}
          Mean:          #{~~stats.mean(times)}
          90% quantile:  #{~~stats.quantile(times, 0.9)}
          Maximum:       #{~~stats.max(times)}
          """
          resolve(times)

  getBenchmarkConfig = ->
    BENCHMARK_URL: process.env.BENCHMARK_URL
    BENCHMARK_STEROIDS_API_KEY: process.env.BENCHMARK_STEROIDS_API_KEY
    BENCHMARK_STEROIDS_APP_ID: process.env.BENCHMARK_STEROIDS_APP_ID
    CONCURRENCY: process.env.CONCURRENCY ? 10
    REQUESTS: process.env.REQUESTS ? 100

  requestRunner = (config) -> ->
    http.request('get', config.BENCHMARK_URL, {
      headers:
        steroidsApiKey: config.BENCHMARK_STEROIDS_API_KEY
        steroidsAppId: config.BENCHMARK_STEROIDS_APP_ID
    })

  grunt.registerTask 'benchmark:http', ->
    done = @async()
    config = getBenchmarkConfig()
    runRequest = requestRunner config
    grunt.log.ok """
    Benchmarking endpoint:    #{config.BENCHMARK_URL}
    Concurrent requests:      #{config.CONCURRENCY}
    Requests to complete:     #{config.REQUESTS}
    """

    time(benchmark(runRequest, config.CONCURRENCY, config.REQUESTS)).then (totalTime) ->
      grunt.log.ok """
      Total time to completion: #{totalTime}
      """
      done()
