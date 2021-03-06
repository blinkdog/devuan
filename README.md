# devuan
`devuan` is intended to provide a JavaScript API for querying and modifying
a system running a [Devuan]-based operating system.

## Install
`devuan` is a [npm] module intended to work with [Node.js]. To install
it, provide the following command:

    npm install devuan

## Usage
To use `devuan` from your own scripts, just `require()` the `devuan`
module like so:

    var DEVUAN = require("devuan");

You can then use the `DEVUAN` object to query and/or modify your Devuan
system.

## API Documentation

### APT
`APT` contains functions for dealing with packages.

### APT.getSourcesListPromise
`getSourcesListPromise` returns a Promise that will resolve to source
objects, in the following form:

    {
      type: "deb",
      uri: "http://ftp.debian.org/debian",
      suite: "wheezy",
      sections: ["main"],
      options: {
        arch: ["amd64", "armel"]
      }
    }

If you provide a directory to `getSourcesListPromise` it will parse the
`.list` files that it finds in that directory. If you do not provide a
directory, then the default system directory `/etc/apt/sources.list.d`
will be used.

### ARCH
`ARCH` contains the Devuan architecture provided by `dpkg`. It is the
output of the following command:

    dpkg --print-architecture

On my system, this is `amd64`, but it may be different on your system.

## Hacking
If you want to make changes to the `devuan` module, you need to set up
a development environment. Change to the directory where you keep your
projects, and then do the following:

    git clone https://github.com/blinkdog/devuan
    cd devuan
    npm install
    cake rebuild

The source files are located in `src/main/coffee`.  
The tests are located in `src/test/coffee`.

The following command will run coverage tests, and open the report in
Mozilla Firefox:

    cake coverage

If you prefer a different browser, edit `BROWSER_COMMAND` at the top of
the `Cakefile` file to your preferred browser.

## License
devuan  
Copyright 2016 Patrick Meade.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

[Devuan]: https://devuan.org/
[Node.js]: https://nodejs.org/
