CMAKE_MINIMUM_REQUIRED(VERSION 2.8.12)
PROJECT(DBTTOOLS)

#
# Install rules.
#

INSTALL(PROGRAMS 
        ${CMAKE_SOURCE_DIR}/bin/dbt-plot-pidstat
        ${CMAKE_SOURCE_DIR}/bin/dbt-plot-sar-blockdev
        ${CMAKE_SOURCE_DIR}/bin/dbt-plot-sar-cpu
        ${CMAKE_SOURCE_DIR}/bin/dbt-plot-sar-mem
        ${CMAKE_SOURCE_DIR}/bin/dbt-plot-sar-net
        ${CMAKE_SOURCE_DIR}/bin/dbt-plot-sar-swap
        ${CMAKE_SOURCE_DIR}/bin/dbt-plot-transaction-distribution
        ${CMAKE_SOURCE_DIR}/bin/dbt-process-pidstat
        ${CMAKE_SOURCE_DIR}/bin/pgsql/dbt-pgsql-generate-db-html
        ${CMAKE_SOURCE_DIR}/bin/pgsql/dbt-pgsql-generate-index-html
        ${CMAKE_SOURCE_DIR}/bin/pgsql/dbt-pgsql-generate-table-html
        ${CMAKE_SOURCE_DIR}/bin/pgsql/dbt-pgsql-plot-database-stats
        ${CMAKE_SOURCE_DIR}/bin/pgsql/dbt-pgsql-plot-index-stats
        ${CMAKE_SOURCE_DIR}/bin/pgsql/dbt-pgsql-plot-table-stats
        DESTINATION "bin")
