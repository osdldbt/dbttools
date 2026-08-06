#!/bin/sh
#
# This file is released under the terms of the Artistic License.
# Please see the file LICENSE, included in this package, for details.
#
# Copyright The DBT Tools Authors
#

SIZE="1600,1000"

# Only remove paths this script created.  The trap is in place before
# these are assigned, so an empty value means there is nothing to do.
# shellcheck disable=SC2317  # invoked by the EXIT trap below
cleanup() {
	if [ -n "${WORKDIR}" ]; then
		rm -rf "${WORKDIR}"
	fi
	if [ -n "${DATAFILE}" ]; then
		rm -f "${DATAFILE}"
	fi
}

# Clean up on every exit path, including the error exits below.  The
# signal handlers only exit: that runs the EXIT trap, which does the
# removal, so there is exactly one cleanup path.
trap cleanup EXIT
trap 'exit 1' HUP INT QUIT ABRT TERM

if [ $# -lt 6 ]; then
	echo "$(basename "${0}") is the DBT transaction rate plotter"
	echo ""
	echo "Usage:"
	echo "  $(basename "${0}") <txn name> <txn id> <rate> <output directory> <color index> <log0> [log1 [...]]"
	echo ""
	echo "Options"
	echo "  txn name            name to use on the chart title"
	echo "  txn id              identifier used in the log file"
	echo "  rate                tps or tpm"
	echo "  output directory    path to output charts"
	echo "  color index         number for selecting plot color"
	echo "  log                 log file to load"
	exit 1
fi

TXN_NAME=$1
shift
TXN_TAG=$1
shift
RATE=$1
shift
OUTPUTDIR=$1
shift
# TODO: Handle color.
shift

mkdir -p "${OUTPUTDIR}"
if [ ! -d "${OUTPUTDIR}" ]; then
	echo "ERROR: Failed to create directory ${OUTPUTDIR}"
	exit 1
fi

if [ "${RATE}" = "tpm" ]; then
	YLABEL="Minute"
elif [ "${RATE}" = "tps" ]; then
	YLABEL="Second"
else
	echo "ERROR: unknown rate ${RATE}"
	exit 1
fi

WORKDIR=$(mktemp -d)
DBFILE="${WORKDIR}/dbttools.db"

sqlite3 "${DBFILE}" << EOF
CREATE TABLE mix(
    "time" INTEGER
  , "txn" TEXT
  , "code" TEXT
  , "response" REAL
  , "id" TEXT
  , "w_id" INTEGER
  , "d_id" INTEGER
);
EOF

for FILE in "${@}"; do
	sqlite3 "${DBFILE}" <<- EOF
		.mode csv
		.import "$FILE" mix
	EOF
done

DATAFILE=$(mktemp)

sqlite3 "${DBFILE}" <<- EOF
	CREATE INDEX mix_time_txn
	ON mix (time,txn);
EOF

# Bucket by minutes elapsed since the earliest event in the logs, per the
# R and Julia versions of this script.  For tps, average each minute over
# the seconds it actually covers so a partial trailing minute is not
# undercounted.
if [ "${RATE}" = "tpm" ]; then
	sqlite3 "${DBFILE}" <<- EOF > "${DATAFILE}"
		SELECT (time - (SELECT min(time) FROM mix)) / 60, count(time)
		FROM mix
		WHERE txn = '${TXN_TAG}'
		GROUP BY 1
		ORDER BY 1;
	EOF
elif [ "${RATE}" = "tps" ]; then
	sqlite3 "${DBFILE}" <<- EOF > "${DATAFILE}"
		SELECT bucket
		     , cast(cnt AS REAL) / min(60, duration - bucket * 60)
		FROM (
		    SELECT (time - (SELECT min(time) FROM mix)) / 60 AS bucket
		         , count(time) AS cnt
		    FROM mix
		    WHERE txn = '${TXN_TAG}'
		    GROUP BY 1
		), (SELECT max(time) - min(time) + 1 AS duration FROM mix)
		ORDER BY bucket;
	EOF
else
	echo "ERROR: unknown rate ${RATE}"
	exit 1
fi

gnuplot << EOF
datafile = "${DATAFILE}"
set datafile separator "|"
set terminal pngcairo size $SIZE
set xlabel "Elapsed Time (minutes)"
set grid
set title "${TXN_NAME} Transaction Rate" noenhanced
set output "${OUTPUTDIR}/t${TXN_TAG}-transaction-rate.png"
set ylabel "Transactions per ${YLABEL}"
set key off
plot datafile using 1:2 notitle with linespoints
EOF

exit 0
