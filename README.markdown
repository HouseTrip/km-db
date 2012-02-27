The `km-db` gem should be useful to KissMetrics (KM) users.
Its aim is to efficiently process data obtained with KM's "Data Export" feature.

It is meant to :

* import KM event dumps into a SQL database (preferably MySQL / PostgreSQL)
* quickly process KM event dumps

Once imported, you can run complex queries against your visit history, for instance run multivariate analysis.

Beware though, KM data can be huge, and processing it is taxing !


Installing
----------

Add this to your Gemfile if you're using Bundler:

    gem 'km-db', :git => 'git://github.com/HouseTrip/km-db.git'


Importing data
--------------

Running reports on raw logs can be less effective than running against a (relational) database.
`km-db` provides a `km_db_import` executable. Run it with:

    $ bundle exec km_db_import <data-dump-directory>…

By default, you events will be imported in `test.db`, a SQLite database.

You can create `km_db.yml` or `config/km_db.yml` to have it import using another adapter, for instance:

    ---- km_db.yml ----
    adapter:  mysql2
    database: km_events
    user:     root

Remember to add `sqlite3-ruby` or `mysql2` to your Gemfile.


Using imported data
-------------------

The `KM::DB` module exposes four `ActiveRecord` classes:
`Event`, `Property`, `User` are the main domain objects.
`Key` is used to intern strings (event and property names) for performance.

### Finding events and properties

All visits during Jan. 2012:

    KM::DB::Event.before('2012-02-1').after('2012-01-01').named('visited site').by_date

All of a user's visit:

    KM::DB::User.last.events.named('visited site')

A user's referers:
    
    KM::DB::User.last.properties.named('referer').map(&:value)

Load some properties with events (uses a left join by default):

    KM::DB::User.last.events.with_properties('a prop', 'another prop').map(&:another_prop)

Note that many more complex queries will require building SQL queries directly.


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
