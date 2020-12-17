# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]
### Added
- this changelog
- rockspec for dev
- two new options to `opts` table for `new()`
  - `opts.timestamps` to add timestamps to data
  - `opts.timeout` to set the connection timeout
- compat53 module for compatibility to lua 5.2 and 5.1
- added add_items() method

### Changed
- moved rockspec to rockspecs subfolder
- renamed to options in `opts` table for `new()`
  - `opts.host` changed to `opts.server`
  - `opts.with_ns` changed to `opts.nanoseconds`
- timestamps are no longer set by default, because they are not mandatory as I first thought (see `opts.timestamps`)

### Fixed
- Used wrong variable name in line 123 (fixed by [evandrofisico](https://codeberg.org/evandrofisico) in [#4](https://codeberg.org/imo/lua-zabbix-sender/pulls/4))

## [0.1.0-0] - 2020-02-18
### Added
- First version
