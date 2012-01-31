The `km-db` gem should be useful to KissMetrics (KM) users.
Its main aim is to efficiently process data obtained with KM's "Data Export" feature.

It is meant to :

* quickly process KM event dumps
* import KM dumps into a SQL database (preferably MySQL / PostgreSQL)

Once imported, you can run complex queries against you visit history, for instance run multivariate analysis.

Beware though, KM data can be huge, and processing it is taxing !

Installing
----------

Add this to your Gemfile if you're using Bundler:

    gem 'km-db', :git => 'git://github.com/HouseTrip/km-db.git'


Processing data
---------------

You don't have to import to filter your data.

The two classes you're looking for are `KM::DB::Parser` and `KM::DB::ParallelParser`.
The latter runs your filter task on all available CPUs, using the `parallel` gem.

The following example counts the number of *aliasing* events in all JSON files under `dumps/`:

    require 'rubygems'
    require 'km/db'

    counter = 0
    parser = KM::DB::Parser.new
    parser.add_filter do |text,event|
        counter += 1 if event['_p2']
    end
    parser.run('dumps/')
    puts counter

Note that it will not work with `ParallelParser`, as the `counter` variable will be different for each process.



Importing data
--------------

`km-db` provides a `km_db_import` executable. Run it with:

    `$ bundle exec km_db_import <data-dump-directory>…`

By default, you events will be imported in `test.db`, a SQLite database.

You can create `km_db.yml` or `config/km_db.yml` to have it import using another adapter, for instance:

    ---- km_db.yml ----
    adapter:  mysql2
    database: km_events
    user:     root

