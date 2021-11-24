# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [1.0.0-0] - 2021-11-24
### Added
- this changelog
- rockspec for dev
- three new options to `opts` table for `new()`
  - `opts.timestamps` to add timestamps to data
  - `opts.timeout` to set the connection timeout
  - `opts.socket` to wrap the socket for example
- added add_items() method

### Changed
- moved rockspec to rockspecs subfolder
- changed dependency for JSON module from `dkjson` to `lunajson`
- renamed two options in `opts` table for `new()`
  - `opts.host` changed to `opts.server`
  - `opts.with_ns` changed to `opts.nanoseconds`
- timestamps are no longer set by default, because they are not mandatory as I first thought (see `opts.timestamps`)
- the module now tries to load he following JSON modules: `cjson`, `lunajson`,`dkjson`
- has_unsent_items() no longer returns a second value
- clear() returns `self` now, instead of `nil`
- using exponentiation operator in `get_time`
- some internal renaming


### Fixed
- Used wrong variable name in line 123 (fixed by [evandrofisico](https://codeberg.org/evandrofisico) in [#4](https://codeberg.org/imo/lua-zabbix-sender/pulls/4))
- Client socket was not closed in case of error


## [0.1.0-0] - 2020-02-18
### Added
- First version
