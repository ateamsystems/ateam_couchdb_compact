# A-Team CouchDB Compactor

A simple script to enumerate all CouchDB databases on a server and then run: a compaction, a view cleanup and a view compaction.

CouchDB does now support automatic DB and view compaction but not view cleanup.  Furthermore many production setups likely want to schedule cleanup during off hours which this script will let you do via cron.

For more information: http://docs.couchdb.org/en/latest/maintenance/compaction.html
