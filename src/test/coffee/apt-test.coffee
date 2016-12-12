# apt-test.coffee
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

MODULE_UNDER_TEST = "../lib/apt"

os = require "os"
proxyquire = require "proxyquire"
should = require "should"

devuan = require "../lib/devuan"

mut = require "#{MODULE_UNDER_TEST}"

describe "apt", ->
  it "should obey the laws of logic", ->
    true.should.equal true

  it "should load the module under test", ->
    mut.should.be.ok()

  describe "filterByNonEmpty", ->
    it "should have the method", ->
      mut.should.have.property "filterByNonEmpty"

    it "should reject empty strings", ->
      {filterByNonEmpty} = mut
      filterByNonEmpty("").should.equal false
      filterByNonEmpty(" ").should.equal false
      filterByNonEmpty("\t").should.equal false
      filterByNonEmpty("\n").should.equal false
      filterByNonEmpty("\r").should.equal false

    it "should keep non-empty strings", ->
      {filterByNonEmpty} = mut
      filterByNonEmpty("alice").should.equal true
      filterByNonEmpty("\tbob ").should.equal true
      filterByNonEmpty("carol\r\n").should.equal true
      filterByNonEmpty("\tdave\n").should.equal true
      filterByNonEmpty("\bEDDIE\b").should.equal true

  describe "getSourcesListPromise", ->
    it "should have the method", ->
      mut.should.have.property "getSourcesListPromise"

    it "should read the default directory if none provided", (done) ->
      pmut = proxyquire "#{MODULE_UNDER_TEST}",
        "fs":
          readdir: (dir, cb) -> done() if dir is mut.ETC_APT_SOURCES_LIST_D
          "@noCallThru": true
        "@noCallThru": true
      pmut.getSourcesListPromise()
      return

    it "should read the provided directory", (done) ->
      pmut = proxyquire "#{MODULE_UNDER_TEST}",
        "fs":
          readdir: (dir, cb) -> done() if dir is "/path/to/my/sources"
          "@noCallThru": true
        "@noCallThru": true
      pmut.getSourcesListPromise "/path/to/my/sources"
      return

    it "should attempt to read each of the list files", (done) ->
      count = 0
      pmut = proxyquire "#{MODULE_UNDER_TEST}",
        "fs":
          readdir: (dir, cb) -> cb null, ["official-package-repositories.list", "official-source-repositories.list"]
          readFile: (file, opts, cb) ->
            count++ if file is "/path/to/my/sources/official-package-repositories.list"
            count++ if file is "/path/to/my/sources/official-source-repositories.list"
            done() if count >= 2
          "@noCallThru": true
        "@noCallThru": true
      pmut.getSourcesListPromise "/path/to/my/sources"
      return

    it "should parse each of the files", (done) ->
      count = 0
      pmut = proxyquire "#{MODULE_UNDER_TEST}",
        "fs":
          readdir: (dir, cb) -> cb null, ["official-package-repositories.list", "official-source-repositories.list"]
          readFile: (file, opts, cb) ->
            if file is "/path/to/my/sources/official-package-repositories.list"
              cb null, """
deb http://mirror.nexcess.net/linuxmint/packages rosa main upstream import

deb http://extra.linuxmint.com rosa main
              """
            else if file is "/path/to/my/sources/official-source-repositories.list"
              cb null, """
deb-src http://mirror.nexcess.net/linuxmint/packages rosa main upstream import

deb-src http://extra.linuxmint.com rosa main
              """
            else
              throw new Error "why are we trying to read #{file} ???"
          "@noCallThru": true
        "@noCallThru": true
      pmut.getSourcesListPromise "/path/to/my/sources"
      .then (sources) ->
        sources.length.should.equal 4
        sources[0].should.eql
          type: "deb"
          uri: "http://mirror.nexcess.net/linuxmint/packages"
          suite: "rosa"
          sections: ["main", "upstream", "import"]
        sources[1].should.eql
          type: "deb"
          uri: "http://extra.linuxmint.com"
          suite: "rosa"
          sections: ["main"]
        sources[2].should.eql
          type: "deb-src"
          uri: "http://mirror.nexcess.net/linuxmint/packages"
          suite: "rosa"
          sections: ["main", "upstream", "import"]
        sources[3].should.eql
          type: "deb-src"
          uri: "http://extra.linuxmint.com"
          suite: "rosa"
          sections: ["main"]
        done()
      return

  describe "mpReadDir", ->
    it "should have the method", ->
      mut.should.have.property "mpReadDir"

    it "should call readdir with the supplied argument", (done) ->
      TEST_DIR = "/path/to/my/directory"
      pmut = proxyquire "#{MODULE_UNDER_TEST}",
        "fs":
          readdir: (dir, cb) -> done() if dir is TEST_DIR
          "@noCallThru": true
        "@noCallThru": true
      pmut.mpReadDir TEST_DIR
      return

    it "should resolve the promise when provided output", (done) ->
      TEST_DIR = "/path/to/my/directory"
      pmut = proxyquire "#{MODULE_UNDER_TEST}",
        "fs":
          readdir: (dir, cb) -> cb null, ["file1.txt", "file2.doc"]
          "@noCallThru": true
        "@noCallThru": true
      pmut.mpReadDir TEST_DIR
      .then (a) ->
        done()
      return

    it "should reject the promise on error", (done) ->
      TEST_DIR = "/path/to/my/directory"
      pmut = proxyquire "#{MODULE_UNDER_TEST}",
        "fs":
          readdir: (dir, cb) -> cb new Error "daleks hacked the database"
          "@noCallThru": true
        "@noCallThru": true
      pmut.mpReadDir TEST_DIR
      .catch (err) ->
        done()
      return

  describe "mpReadFile", ->
    it "should have the method", ->
      mut.should.have.property "mpReadFile"

    it "should call readFile with the supplied argument", (done) ->
      TEST_FILE = "/path/to/my/file"
      pmut = proxyquire "#{MODULE_UNDER_TEST}",
        "fs":
          readFile: (file, opt, cb) -> done() if file is TEST_FILE
          "@noCallThru": true
        "@noCallThru": true
      pmut.mpReadFile TEST_FILE
      return

    it "should resolve the promise when provided output", (done) ->
      TEST_FILE = "/path/to/my/file"
      pmut = proxyquire "#{MODULE_UNDER_TEST}",
        "fs":
          readFile: (file, opt, cb) -> cb null, "Exterminate! Exterminate!"
          "@noCallThru": true
        "@noCallThru": true
      pmut.mpReadFile TEST_FILE
      .then (a) ->
        done() if a is "Exterminate! Exterminate!"
      return

    it "should reject the promise on error", (done) ->
      TEST_FILE = "/path/to/my/file"
      pmut = proxyquire "#{MODULE_UNDER_TEST}",
        "fs":
          readFile: (file, opt, cb) -> cb new Error "daleks hacked the database"
          "@noCallThru": true
        "@noCallThru": true
      pmut.mpReadFile TEST_FILE
      .catch (err) ->
        done()
      return

  describe "parseSourceLine", ->
    it "should have the method", ->
      mut.should.have.property "parseSourceLine"

    it "should handle degenerate cases", ->
      {parseSourceLine} = mut
      should(parseSourceLine undefined).equal undefined
      should(parseSourceLine null).equal null
      should(parseSourceLine []).eql []
      should(parseSourceLine {}).eql {}
      should(parseSourceLine (->)).eql (->)

    it "should handle some normal cases", ->
      {parseSourceLine} = mut
      parseSourceLine("deb file:/home/jason/debian stable main contrib non-free").should.eql
        type: "deb"
        uri: "file:/home/jason/debian"
        suite: "stable"
        sections: ["main", "contrib", "non-free"]
      parseSourceLine("deb file:/home/jason/debian unstable main contrib non-free").should.eql
        type: "deb"
        uri: "file:/home/jason/debian"
        suite: "unstable"
        sections: ["main", "contrib", "non-free"]
      parseSourceLine("deb-src file:/home/jason/debian unstable main contrib non-free").should.eql
        type: "deb-src"
        uri: "file:/home/jason/debian"
        suite: "unstable"
        sections: ["main", "contrib", "non-free"]
      parseSourceLine("deb http://ftp.debian.org/debian wheezy main").should.eql
        type: "deb"
        uri: "http://ftp.debian.org/debian"
        suite: "wheezy"
        sections: ["main"]
      parseSourceLine("deb [ arch=amd64,armel ] http://ftp.debian.org/debian wheezy main").should.eql
        type: "deb"
        uri: "http://ftp.debian.org/debian"
        suite: "wheezy"
        sections: ["main"]
        options:
          arch: ["amd64", "armel"]
      parseSourceLine("deb http://archive.debian.org/debian-archive hamm main").should.eql
        type: "deb"
        uri: "http://archive.debian.org/debian-archive"
        suite: "hamm"
        sections: ["main"]
      parseSourceLine("deb ftp://ftp.debian.org/debian wheezy contrib").should.eql
        type: "deb"
        uri: "ftp://ftp.debian.org/debian"
        suite: "wheezy"
        sections: ["contrib"]
      parseSourceLine("deb ftp://ftp.debian.org/debian unstable contrib").should.eql
        type: "deb"
        uri: "ftp://ftp.debian.org/debian"
        suite: "unstable"
        sections: ["contrib"]
      parseSourceLine("deb http://ftp.tlh.debian.org/universe unstable/binary-$(ARCH)/").should.eql
        type: "deb"
        uri: "http://ftp.tlh.debian.org/universe"
        suite: "unstable/binary-#{devuan.ARCH}/"
        sections: []

  describe "parseSourceLineOptions", ->
    it "should have the method", ->
      mut.should.have.property "parseSourceLineOptions"

    it "should handle degenerate cases", ->
      {parseSourceLineOptions} = mut
      should(parseSourceLineOptions undefined).equal undefined
      should(parseSourceLineOptions null).equal null
      should(parseSourceLineOptions []).eql []
      should(parseSourceLineOptions {}).eql {}
      should(parseSourceLineOptions (->)).eql (->)

    it "should handle single option single value", ->
      {parseSourceLineOptions} = mut
      parseSourceLineOptions(" arch=amd64 ").should.eql
        arch: "amd64"

    it "should handle single option multi value", ->
      {parseSourceLineOptions} = mut
      parseSourceLineOptions(" arch=amd64,armel ").should.eql
        arch: ["amd64", "armel"]

    it "should handle multi option single value", ->
      {parseSourceLineOptions} = mut
      parseSourceLineOptions(" arch=amd64 trusted=yes ").should.eql
        arch: "amd64"
        trusted: "yes"

    it "should handle multi option multi value", ->
      {parseSourceLineOptions} = mut
      parseSourceLineOptions(" arch=amd64,armel trusted=yes ").should.eql
        arch: ["amd64", "armel"]
        trusted: "yes"

  describe "parseSourcesList", ->
    it "should have the method", ->
      mut.should.have.property "parseSourcesList"

    it "should give back several objects", ->
      {parseSourcesList} = mut
      SOURCES_LIST = """
deb http://mirror.nexcess.net/linuxmint/packages rosa main upstream import

deb http://extra.linuxmint.com rosa main

deb http://mirror.nexcess.net/ubuntu trusty main restricted universe multiverse
deb http://mirror.nexcess.net/ubuntu trusty-updates main restricted universe multiverse

deb http://security.ubuntu.com/ubuntu/ trusty-security main restricted universe multiverse
deb http://archive.canonical.com/ubuntu/ trusty partner
      """
      parseSourcesList(SOURCES_LIST).should.eql [
        {
          type: "deb"
          uri: "http://mirror.nexcess.net/linuxmint/packages"
          suite: "rosa"
          sections: ["main", "upstream", "import"]
        },
        {
          type: "deb"
          uri: "http://extra.linuxmint.com"
          suite: "rosa"
          sections: ["main"]
        },
        {
          type: "deb"
          uri: "http://mirror.nexcess.net/ubuntu"
          suite: "trusty"
          sections: ["main", "restricted", "universe", "multiverse"]
        },
        {
          type: "deb"
          uri: "http://mirror.nexcess.net/ubuntu"
          suite: "trusty-updates"
          sections: ["main", "restricted", "universe", "multiverse"]
        },
        {
          type: "deb"
          uri: "http://security.ubuntu.com/ubuntu/"
          suite: "trusty-security"
          sections: ["main", "restricted", "universe", "multiverse"]
        },
        {
          type: "deb"
          uri: "http://archive.canonical.com/ubuntu/"
          suite: "trusty"
          sections: ["partner"]
        }
      ]

  describe "reduceByConcat", ->
    it "should have the method", ->
      mut.should.have.property "reduceByConcat"

    it "should call concat on the first argument", (done) ->
      argB = []
      argA =
        concat: -> done()
      mut.reduceByConcat argA, argB

    it "should provide the second argument to the concat call", (done) ->
      argB = []
      argA =
        concat: (x) -> done() if x is argB
      mut.reduceByConcat argA, argB

  describe "removeHashComment", ->
    it "should have the method", ->
      mut.should.have.property "removeHashComment"

    it "should handle degenerate cases", ->
      {removeHashComment} = mut
      should(removeHashComment undefined).equal undefined
      should(removeHashComment null).equal null
      should(removeHashComment []).eql []
      should(removeHashComment {}).eql {}
      should(removeHashComment (->)).eql (->)

    it "should pass non-comments without change", ->
      {removeHashComment} = mut
      removeHashComment("").should.equal ""
      removeHashComment(" ").should.equal " "
      removeHashComment(" ^_^ ").should.equal " ^_^ "
      removeHashComment("deb http://security.ubuntu.com/ubuntu/ trusty-security main restricted universe multiverse").should.equal "deb http://security.ubuntu.com/ubuntu/ trusty-security main restricted universe multiverse"

    it "should return empty on comments that begin a line", ->
      {removeHashComment} = mut
      removeHashComment("# this is a comment").should.equal ""
      removeHashComment("# yep, an even longer comment").should.equal ""
      removeHashComment("# boy # somebody # likes # hash symbols").should.equal ""
      removeHashComment("### multiple hash symbols even").should.equal ""

    it "should return leading spaces if necessary", ->
      {removeHashComment} = mut
      removeHashComment(" # this is a comment").should.equal " "
      removeHashComment("  # yep, an even longer comment").should.equal "  "
      removeHashComment("   # boy # somebody # likes # hash symbols").should.equal "   "
      removeHashComment(" ### multiple hash symbols even").should.equal " "

    it "should remove the comment portion of the line", ->
      {removeHashComment} = mut
      removeHashComment("foo = bar # this is a comment").should.equal "foo = bar "
      removeHashComment("bar::baz = foo  # yep, an even longer comment").should.equal "bar::baz = foo  "
      removeHashComment("drwho.dalek = 'Exterminate!'   # boy # somebody # likes # hash symbols").should.equal "drwho.dalek = 'Exterminate!'   "
      removeHashComment("multi=false ### multiple hash symbols even").should.equal "multi=false "

#----------------------------------------------------------------------
# end of apt-test.coffee
