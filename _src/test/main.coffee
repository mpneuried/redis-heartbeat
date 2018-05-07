should = require('should')

Heartbeat = require( "../." )
redis = require( "redis" )

METRICKEYS = ["t", "g_cpu", "g_mem", "g_memtotal", "p_id", "p_uptime", "p_mem", "p_cpu"]

describe "----- Module TESTS -----", ->


	describe 'Create Instance', ->

		it "without any options", ( done )->
			_hb = new Heartbeat( autostart: false )
			_hb.on "error", ( _err )->
				_err.name.should.equal( "ENONAME" )
				done()
				_hb.removeAllListeners()
				_hb.quit()
				return
			_hb.start()
			return

		it "without identifier option", ( done )->
			_hb = new Heartbeat( { name: "FAIL", autostart: false } )
			_hb.on "error", ( _err )->
				_err.name.should.equal( "ENOIDENTIFIER" )
				done()
				_hb.removeAllListeners()
				_hb.quit()
				return
			_hb.start()
			return

		it "without name option", ( done )->
			_hb = new Heartbeat( { identifier: "explode", autostart: false } )
			_hb.on "error", ( _err )->
				_err.name.should.equal( "ENONAME" )
				done()
				_hb.removeAllListeners()
				_hb.quit()
				return
			_hb.start()
			return

		return


	describe 'Main Tests', ->
		_hb = null
		_ident = "bar:4223"
		before ( done )->
			_hb = new Heartbeat( { name: "FOO", identifier: _ident, intervalHeartbeat: 1, intervalMetrics: 5, metricCount: 10 } )
			_hb.on "error", ( _err )->
				console.error( "ERROR", _err )
				return
			done()
			return

		after ( done )->
			_hb.quit()
			done()
			return

		# Implement tests cases here
		it "first test", ( done )->
			this.timeout( 11000 )
			_cH = 0
			_cM = 0

			_hb.on "beforeHeartbeat", ( ident )->
				_cH++
				ident.should.equal( _ident )
				return

			setTimeout( ->
				_cH.should.be.above( 0 )
				done()
				return
			, 10000)
			return

		return

	describe 'Expire Tests', ->
		_hb = null
		_cli = null
		_ident = "foo:1337"

		before ( done )->
			_cli = redis.createClient()
			_hb = new Heartbeat( { metricExpire: 10, heartbeatExpire: 10, name: "BAR", identifier: _ident, intervalHeartbeat: 1, intervalMetrics: 5, metricCount: 10, client: _cli } )
			_hb.on "error", ( _err )->
				console.error( "ERROR", _err )
				return
			done()
			return

		after ( done )->
			_hb.quit()
			done()
			return

		# Implement tests cases here
		it "wait for heartbeats", ( done )->
			this.timeout( 11000 )
			_cH = 0

			_hb.on "beforeHeartbeat", ( ident )->
				_cH++
				ident.should.equal( _ident )
				return

			setTimeout( ->
				_cH.should.be.above( 0 )
				done()
				return
			, 10000)
			return

		it "stop", ( done )->
			_hb.stop()

			_hb.on "beforeHeartbeat", ->
				throw new Error( "Heartbeat should be stopped ..." )
				return

			@timeout( 4000 )
			setTimeout( done, 3000 )
			return

		it "wait for 10 seconds for the expired keys", ( done )->
			console.log "        wait until keys are expired ..."
			@timeout( 11000 )
			setTimeout done, 10000
			return

		it "check for expired keys", ( done )->
			
			_cli.keys "HB:METRICS:foo*", ( err, keys )->
				if err
					throw err

				if keys?.length
					console.error "Found keys:", keys
					throw new Error( "there should be no keys like 'HB:METRICS:foo*'" )

				_cli.keys "HB:BAR*", ( err, keys )->
					if err
						throw err

					if keys?.length
						console.error "Found keys:", keys
						throw new Error( "there should be no keys like 'HB:BAR*'" )
					
					done()
					return
				return
			return

		return
	return
