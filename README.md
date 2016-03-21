# An attempt to transfer Derby data to MySQL

You'll need Jruby and a running MySQL server.
Configure the MySQL connection in the db_transfer.rb file ( in the jdbc URL line ).
You'll also need to have the MySQL db setup for ArchivesSpace ( doing the
scripts/setup-database.sh|bat) with the same version that ran the derby db. 


0. run bundle install to get the required libraries.
1. put your archivesspace derby db in directory named "data"
2. make a directory named "exports"
3. setup your mysql database, with the archivesspace schema ( use  scripts/setup-database.sh|bat )
5. run "bundle exec ruby db_transfer.rb"

Your derby data will be spit out into tsv files ( stored in the exports directory ), which will be then imported into your mysql DB.

Good luck.

