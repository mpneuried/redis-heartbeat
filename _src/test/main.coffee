should = require('should')

Heartbeat = require( "../." ) 

_hb = null

describe "----- Module TESTS -----", ->

	before ( done )->
		_hb = new Heartbeat( { name: "FOO", identifier: "bar:4223", intervalHeartbeat: 1, intervalMetrics: 5, metricCount: 10 } )
		# TODO add initialisation Code
		done()
		return

	after ( done )->
		#  TODO teardown
		done()
		return

	describe 'Main Tests', ->

		# Implement tests cases here
		it "first test", ( done )->
			this.timeout( 31000 )
			setTimeout done, 30000
			return

		return
	return