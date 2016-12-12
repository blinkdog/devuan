# devuan.coffee
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

{exec} = require "child_process"
os = require "os"

exports.APT = require "./apt"

# update the architecture to the one expected by dpkg
new Promise (resolve, reject) ->
  exec "dpkg --print-architecture", (err, stdout, stderr) ->
    return reject err if err?
    resolve stdout.trim()
.then (arch) ->
  exports.ARCH = arch
.catch (err) ->
  exports.ARCH = os.arch()

#----------------------------------------------------------------------
# end of devuan.coffee
