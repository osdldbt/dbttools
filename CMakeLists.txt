CMAKE_MINIMUM_REQUIRED(VERSION 2.8.12)
PROJECT(DBTTOOLS)

SET(PROJECT_VERSION_MAJOR 0)
SET(PROJECT_VERSION_MINOR 1)
SET(PROJECT_VERSION_PATCH 0)

SET(PROJECT_VERSION
    ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}.${PROJECT_VERSION_PATCH})

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
        ${CMAKE_SOURCE_DIR}/bin/pgsql/dbt-pgsql-generate-db-report
        ${CMAKE_SOURCE_DIR}/bin/pgsql/dbt-pgsql-generate-index-html
        ${CMAKE_SOURCE_DIR}/bin/pgsql/dbt-pgsql-generate-index-report
        ${CMAKE_SOURCE_DIR}/bin/pgsql/dbt-pgsql-generate-table-html
        ${CMAKE_SOURCE_DIR}/bin/pgsql/dbt-pgsql-generate-table-report
        ${CMAKE_SOURCE_DIR}/bin/pgsql/dbt-pgsql-plot-database-stats
        ${CMAKE_SOURCE_DIR}/bin/pgsql/dbt-pgsql-plot-index-stats
        ${CMAKE_SOURCE_DIR}/bin/pgsql/dbt-pgsql-plot-table-stats
        DESTINATION "bin")

SET(CPACK_CMAKE_GENERATOR "Unix Makefiles")
SET(CPACK_GENERATOR "TXZ;ZIP")

SET(CPACK_PACKAGE_NAME "dbttools")
SET(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Database Test Tools")
SET(CPACK_PACKAGE_VENDOR "osdldbt")

set (CPACK_PACKAGE_VERSION "${PROJECT_VERSION}")
set (CPACK_SOURCE_PACKAGE_FILE_NAME "${PROJECT_NAME}-${PROJECT_VERSION}")

SET(CPACK_INSTALL_CMAKE_PROJECTS "")

SET(CPACK_PACKAGE_DESCRIPTION_FILE "README")
SET(CPACK_RESOURCE_FILE_LICENSE "LICENSE")

set (CPACK_IGNORE_FILES "${CPACK_IGNORE_FILES};/\\\\.git/")
set (CPACK_IGNORE_FILES "${CPACK_IGNORE_FILES};\\\\.gitignore\\$")
set (CPACK_IGNORE_FILES "${CPACK_IGNORE_FILES};\\\\.swp$")
set (CPACK_IGNORE_FILES "${CPACK_IGNORE_FILES};\\\\.tar.*")
set (CPACK_IGNORE_FILES "${CPACK_IGNORE_FILES};_CPack_Packages/")
set (CPACK_IGNORE_FILES "${CPACK_IGNORE_FILES};CMakeFiles/")
set (CPACK_IGNORE_FILES "${CPACK_IGNORE_FILES};CPackConfig.cmake")
set (CPACK_IGNORE_FILES "${CPACK_IGNORE_FILES};CPackSourceConfig.cmake")
set (CPACK_IGNORE_FILES "${CPACK_IGNORE_FILES};README-CMAKE")
set (CPACK_IGNORE_FILES "${CPACK_IGNORE_FILES};cmake_install.cmake\\$")
set (CPACK_IGNORE_FILES "${CPACK_IGNORE_FILES};tags")

INCLUDE(CPack)
