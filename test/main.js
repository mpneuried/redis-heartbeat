(function() {
  var Heartbeat, should, _hb;

  should = require('should');

  Heartbeat = require("../.");

  _hb = null;

  describe("----- Module TESTS -----", function() {
    before(function(done) {
      _hb = new Heartbeat({
        name: "FOO",
        identifier: "bar:4223",
        intervalHeartbeat: 1,
        intervalMetrics: 5,
        metricCount: 10
      });
      done();
    });
    after(function(done) {
      done();
    });
    describe('Main Tests', function() {
      it("first test", function(done) {
        this.timeout(31000);
        setTimeout(done, 30000);
      });
    });
  });

}).call(this);
