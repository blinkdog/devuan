# apt.coffee
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

fs = require "fs"
path = require "path"

devuan = require "./devuan"

ETC_APT_SOURCES_LIST_D = "/etc/apt/sources.list.d"
exports.ETC_APT_SOURCES_LIST_D = ETC_APT_SOURCES_LIST_D

filterByNonEmpty = (a) -> return a.trim().length > 0
exports.filterByNonEmpty = filterByNonEmpty

getSourcesListPromise = (sourcesDir) ->
  sourcesDir ?= ETC_APT_SOURCES_LIST_D
  # read the sources directory to determine which list files live there
  mpReadDir sourcesDir
  .then (files) ->
    # construct the full paths to those list files
    filePaths = (path.join(sourcesDir, file) for file in files)
    return filePaths
  .then (paths) ->
    # read the contents of each of the list files
    return Promise.all (mpReadFile(filePath) for filePath in paths)
  .then (contents) ->
    # parse the contents of each of list files into source objects
    return contents.map (a) -> return parseSourcesList a
  .then (sources) ->
    # flatten out the array of sources
    return sources.reduce reduceByConcat, []
exports.getSourcesListPromise = getSourcesListPromise

mpReadDir = (dir) ->
  return new Promise (resolve, reject) ->
    fs.readdir dir, (err, files) ->
      return reject err if err?
      resolve files
exports.mpReadDir = mpReadDir

UTF8_ENCODING =
  encoding: "utf8"
exports.UTF8_ENCODING = UTF8_ENCODING

mpReadFile = (file) ->
  return new Promise (resolve, reject) ->
    fs.readFile file, UTF8_ENCODING, (err, data) ->
      return reject err if err?
      resolve data
exports.mpReadFile = mpReadFile

LINE_RE = /^(deb|deb-src)\s((\[([^\]]+)\])\s)*(.*)$/i
exports.LINE_RE = LINE_RE

parseSourceLine = (line) ->
  return line if not line?.split?
  line = line.replace "$(ARCH)", devuan.ARCH
  reParsed = LINE_RE.exec line
  type = reParsed[1]
  options = parseSourceLineOptions reParsed[4]
  [uri, suite, sections...] = reParsed[5].split " "
  lineObj =
    type: type
    uri: uri
    suite: suite
    sections: sections
  lineObj.options = options if options?
  return lineObj
exports.parseSourceLine = parseSourceLine

OPT_RE = /^([^\-\+\=]+)\-*\+*\=+(.+)$/i
exports.OPT_RE = OPT_RE

parseSourceLineOptions = (opt) ->
  return opt if not opt?.split?
  opt = opt.trim()
  opts = opt.split " "
  retVal = {}
  for option in opts
    optParts = OPT_RE.exec option
    values = optParts[2].split ","
    if values.length > 1
      retVal[optParts[1]] = values
    else
      retVal[optParts[1]] = values[0]
  return retVal
exports.parseSourceLineOptions = parseSourceLineOptions

parseSourcesList = (contents) ->
  contents
  .split "\n"
  .map removeHashComment
  .filter filterByNonEmpty
  .map parseSourceLine
exports.parseSourcesList = parseSourcesList

reduceByConcat = (a,b) -> return a.concat b
exports.reduceByConcat = reduceByConcat

removeHashComment = (a) ->
  return a if not a?.indexOf?
  hashIndex = a.indexOf "#"
  return a if hashIndex is -1
  return a.substring 0, hashIndex
exports.removeHashComment = removeHashComment

#----------------------------------------------------------------------
# end of apt.coffee
