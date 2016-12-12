# devuan-test.coffee
# Copyright 2016 Patrick Meade.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#----------------------------------------------------------------------

MODULE_UNDER_TEST = "../lib/devuan"

os = require "os"
proxyquire = require "proxyquire"
should = require "should"

mut = require "#{MODULE_UNDER_TEST}"

describe "devuan", ->
  it "should obey the laws of logic", ->
    true.should.equal true

  it "should load the module under test", ->
    mut.should.be.ok()

  describe "ARCH", ->
    it "should load the arch from dpkg", (done) ->
      pmut = proxyquire MODULE_UNDER_TEST,
        "@noCallThru": true
        "child_process":
          "@noCallThru": true
          exec: (cmd, cb) ->
            cb null, "amd64\n", ""
      setImmediate ->
        done() if pmut.ARCH is "amd64"

    it "should default to os.arch() if dpkg fails", (done) ->
      pmut = proxyquire MODULE_UNDER_TEST,
        "@noCallThru": true
        "child_process":
          "@noCallThru": true
          exec: (cmd, cb) ->
            cb new Error "daleks in the database"
      setImmediate ->
        done() if pmut.ARCH is "#{os.arch()}"

#----------------------------------------------------------------------
# end of devuan-test.coffee
