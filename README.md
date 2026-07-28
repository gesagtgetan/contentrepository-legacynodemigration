# Content Repository Migration

> Our fork of [neos/contentrepository-legacynodemigration](https://github.com/neos/contentrepository-legacynodemigration),
> carrying migration fixes that are not in an upstream release yet.
> Use branch `9.1` for Neos 9.1 and branch `9.0` for Neos 9.0.

## Installation

The package name is unchanged, so this is a drop-in replacement:

``` bash
composer config repositories.legacynodemigration vcs git@github.com:gesagtgetan/contentrepository-legacynodemigration.git
composer require --dev "neos/contentrepository-legacynodemigration:9.1.x-dev"
```

If the package is already required, that same command is all you need: composer moves it from `require` to
`require-dev` and replaces the constraint. Leaving a tagged constraint in place would silently keep you on
the upstream package.

Use `9.0.x-dev` for Neos 9.0, which needs a project tracking `9.0.x-dev`. The `9.1` branch also installs on
tagged 9.1 releases from 9.1.7 upwards (earlier releases lack core methods the patches rely on).

Because the name matches upstream, composer silently installs the unfixed upstream package if the
repository entry is missing. Verify with `composer show neos/contentrepository-legacynodemigration`: it has
to report `9.1.x-dev`, not a release such as `9.1.7`.

## The `!!!FORKONLY` commit prefix

Commits prefixed with `!!!FORKONLY` add code that does not belong into this package: methods duplicated or
reimplemented from `neos/contentrepository-core`, placed here because the alternative would be forking and
patching the core package as well. Each commit body names the core counterpart. These duplicates have to be
kept in sync with their core originals, and can be dropped (adapting their callers) once the core exposes
the respective API.

-----

#### Migrating an existing (Neos < 9.0) Site

``` bash
# the following config points to a Neos 8.0 database (adjust to your needs)
./flow site:exportLegacyData --path ./migratedContent --config '{"dbal": {"dbname": "neos80"}, "resourcesPath": "/path/to/neos-8.0/Data/Persistent/Resources"}'
# import the migrated data
./flow site:importAll --path ./migratedContent
```
