# KMDB

The `km-db` gem should be useful to KissMetrics (KM) users.
Its aim is to efficiently process data obtained with KM's "Data Export" feature.

Its main feature is to import dumps directly from S3 into a SQL database,
optimized for typical queries (in particular, partitioned along the time
dimension).

Once imported, you can run complex queries against your visit history, for
instance run multivariate analysis.

Beware though, KM data can be huge, and processing it is taxing!


## Installing

If you want to run "just" KM-DB, you might want to just use [the
app](https://github.com/HouseTrip/km-db-app).

Otherwise, add this to your Gemfile if you're using Bundler:

    gem 'km-db'

### Configuration

KMDB is configured through environment variables. We recommend storing this
settings in a `.env` file if running locally, and using [foreman]() to start
KMDB commands with the environment set.


### Preparing your database

KMDB requires a MySQL database (to store events, properties, etc) and a Redis
store running (to store batch jobs and cache data).

Set the following:

- `DATABASE_URL` (required), e.g. `mysql2://km_db_test@localhost/km_db_test`
- `KMDB_REDIS_URL` [localhost], e.g. `redis://localhost/14`

Then run:

    $ kmdb-flush

to prepare your database.


### Optimizing your database

If your dataset is large (over 1 million events), KMDB can [partition]() your
database, i.e. transparently split large tables into smaller buckets of
continuous time periods.

Set the following:

- `KMDB_MIN_DATE` (required), e.g. '2014-01-01'
- `KMDB_MAX_DATE` (required), e.g. '2016-01-01'
- `KMDB_DAYS_PER_PARTITION` (required), e.g. '7'

Then run:

    $ kmdb-partition

Notes:

- MySQL only supports up to 1024 partitions.
- You shoud aim for less than 1 million events per partitions for performance.
- You should run this _before_ importing data, but it's possible to re-run it.
  The `MIN_DATE` will be ignored, and partitions will be added up to the new
  `MAX_DATE` (if larger).


## Importing data

KMDB will fetch JSON files form the S3 bucket where you instructed KissMetrics
to back up your data, parse them, and store information in the database.

It does so using [resque]() for high parallelism of the import process; in our
experience, it's perfectly possible to import 100GB of data in a few hours.

Set the following: 

- `RESQUE_WORKERS` (1), number of worker nodes.
- `KMDB_MIN_REVISION` (optional, default 1), first KissMetrics revision file you want to import.
- `KMDB_REVISION_LOOKAHEAD` (10), how many revision files to check after the last known one
- `KMDB_BATCH_SIZE` (100), how many events to process per batch (advisory, may
  be higher as an entire second's worth of events will always be processed in one
  batch to preserve ordering).
- `AWS_BUCKET` (required), the name of the S3 bucket where the data is stored.
- `AWS_ACCESS_KEY_ID` (required).
- `AWS_SECRET_ACCESS_KEY` (required).


### Ignoring some users

You may want to ignore all events and properties for certain users, for instance
the administrative users of your site (or employees).

Simply add their identities to the `ignored_users` table before import. 


### Whitelisting events

It's typical to have some noisy and/or shorter-lived events sent to KissMetrics,
e.g. for testing purposes or for temporary monitoring.

Should you only want to import certain events, add their names to the
`whitelisted_events` table before starting import.

If the table is left empty, all events will be imported.


### Dealiasing users

When KissMetrics finds a way to tie two user identities as being a single actual
user, it stores an "aliasing" event.
KMDB de-aliases users automatically during import, and will store all events and
properties against a single user identity (one that's numeric if any, otherwise
the lexicographically lowest).


## Using imported data

### Using SQL directly

KMDB tries to stay close to the KissMetrics data, leaving you to interpret it.
As such, the main tables are unsurprisingly `events` and `properties`.

Here's a summary of the data model:

`events` has one row for each imported event:

| **events** |
|------------|
| id         |
| t          | the event timestamp             |
| n          | reference to the event name     |
| user_id    | reference to the user           |

`properties` has one row for each property ever set on events or users

| **properties** |
|----------------|
| id             |
| t              | timestamp at which the property was set  |
| key            | reference to the property name           |
| value          | value (string)                           |
| user_id        | reference to the user                    |
| event_id       | reference to the event (may be NULL)     |

`events.n` and `properties.key` reference the `id` column of the `keys` table;
this is done for performance reasons (event and property names are only stored
once):

| **keys** |
|----------|
| id       |
| string   |

KMDB also keeps the original user identities around in `users`, although you'll
probably never need them:

| **users** |
|-----------|
| id        |
| name      | the identity given by KissMetrics |

as well as all aliasing events:

| **aliases** |
|-------------|
| id          |
| name1       |
| name2       |


### Using ActiveRecord

The `KMDB` module exposes four `ActiveRecord` classes:
`Event`, `Property`, `User` are the main domain objects.

`Key` is used to intern strings (event and property names) for performance.

Please consult the source of these models for details.

