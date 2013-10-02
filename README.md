# ACF Manager

Simple application to work with Steam ACF files.


## Features

* Export data from ACF files to several formats (csv, yml, json, xml, vdf)
* Support for multiple Steam libraries
* Locate unused steam game directories (those which aren't referenced in any ACF)
* Supports Windows, Linux, Mac OS X


## Installation

`git clone https://github.com/davispuh/ACF-Manager.git`

### Dependencies

gems:

* `steam_codec` (required)
* `json` (optional, to export in JSON format)
* `gyoku` (optional, to export in XML format)

install manually (`gem install`) or with

`bundle install`

## Usage

for command information use `-h` or `--help` flag

`ruby acf_manager.rb -h`

```
Usage: acf_manager.rb [options]
    -p, --paths steam                Paths to Steam directories
    -a, --apps paths                 Paths to SteamApps directories
    -e, --execute ACTION             Execute specified action (export, list)
    -f, --fields fields              Specify which fields to export
    -m, --mode MODE                  Mode for `list` (downloaded, installed,
                                     unreferenced)
    -o, --output FORMAT              Output format (csv, yml, json, xml, vdf)
    -s, --save FILE                  File where to save output
    -h, --help                       Show this message
```

* `-p, --paths` comma separated list of locations to Steam directories, example `-p "C:\Steam","D:\Steam"`
* `-a, --apps` comma separated list of locations to SteamApps directories, example `-p "C:\Steam\SteamApps","D:\Steam\SteamApps"`
* `-e, --execute ACTION`, example `-e export` or `-e list`
* `-f, --fields fields`, comma separated list of fields, example `-f AppID,InstallDir,UserConfig.Name` (used only for `export`)
* `-m, --mode MODE`, comma separated list of fields, example `-m installed`  (used only for `list`)
* `-o, --output FORMAT`, file format for output, example `-o json`
* `-s, --save FILE`, file path where to save, example `-s C:\apps.json`


## Documentation

YARD with markdown is used for documentation (`redcarpet` required)

## Specs

RSpec and simplecov are required, to run tests just `rake spec`
code coverage will also be generated

## Unlicense

![Copyright-Free](http://unlicense.org/pd-icon.png)

All text, documentation, code and files in this repository are in public domain (including this text, README).
It means you can copy, modify, distribute and include in your own work/code, even for commercial purposes, all without asking permission.

[About Unlicense](http://unlicense.org/)

## Contributing

Feel free to improve anything.

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request


**Warning**: By sending pull request to this repository you dedicate any and all copyright interest in pull request (code files and all other) to the public domain. (files will be in public domain even if pull request doesn't get merged)

Also before sending pull request you acknowledge that you own all copyrights or have authorization to dedicate them to public domain.

If you don't want to dedicate code to public domain or if you're not allowed to (eg. you don't own required copyrights) then DON'T send pull request.

