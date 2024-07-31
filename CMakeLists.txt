CMAKE_MINIMUM_REQUIRED(VERSION 3.5.0)
PROJECT(DBTTOOLS NONE)

SET(PROJECT_VERSION_MAJOR 0)
SET(PROJECT_VERSION_MINOR 5)
SET(PROJECT_VERSION_PATCH 1)

SET(PROJECT_VERSION
    ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}.${PROJECT_VERSION_PATCH})

#
# Install rules.
#

configure_file(
    bin/dbt-version.in
    ${CMAKE_BINARY_DIR}/dbt-version
)

INSTALL(PROGRAMS 
        ${CMAKE_BINARY_DIR}/dbt-version
        ${CMAKE_SOURCE_DIR}/bin/dbt-plot
        ${CMAKE_SOURCE_DIR}/bin/dbt-plot-transaction-distribution.gnuplot
        ${CMAKE_SOURCE_DIR}/bin/dbt-plot-transaction-distribution.jl
        ${CMAKE_SOURCE_DIR}/bin/dbt-plot-transaction-distribution.r
        ${CMAKE_SOURCE_DIR}/bin/dbt-plot-transaction-rate.gnuplot
        ${CMAKE_SOURCE_DIR}/bin/dbt-plot-transaction-rate.jl
        ${CMAKE_SOURCE_DIR}/bin/dbt-plot-transaction-rate.r
        ${CMAKE_SOURCE_DIR}/bin/pgsql/dbt-pgsql-generate-db-report
        ${CMAKE_SOURCE_DIR}/bin/pgsql/dbt-pgsql-generate-index-report
        ${CMAKE_SOURCE_DIR}/bin/pgsql/dbt-pgsql-generate-table-report
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
