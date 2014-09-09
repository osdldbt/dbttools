CMAKE_MINIMUM_REQUIRED(VERSION 2.4)
PROJECT(DBTTOOLS)

#
# Install rules.
#

INSTALL(PROGRAMS 
        bin/dbt-plot-sar-blockdev
        bin/dbt-plot-sar-cpu
        bin/dbt-plot-transaction-distribution
        bin/pgsql/dbt-pgsql-plot-database-stats
        bin/pgsql/dbt-pgsql-plot-index-stats
        bin/pgsql/dbt-pgsql-plot-table-stats
        DESTINATION "/bin")
