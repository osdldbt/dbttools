#!/bin/sh
#
# This file is released under the terms of the Artistic License.
# Please see the file LICENSE, included in this package, for details.
#
# Copyright The DBT Tools Authors
#

SIZE="1600,1000"

cleanup() {
	rm -rf "${TMPDIR}" "${DATAFILE}"
}

trap cleanup INT QUIT ABRT TERM

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

TMPDIR=$(mktemp -d)
DBFILE="${TMPDIR}/dbttools.db"

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
		.import $FILE mix
	EOF
done

DATAFILE=$(mktemp)

sqlite3 "${DBFILE}" <<- EOF
.mode csv
.import $DATAFILE mix
CREATE INDEX mix_time_txn
ON mix (time,txn);
EOF

if [ "${RATE}" = "tpm" ]; then
	sqlite3 "${DBFILE}" <<- EOF > "${DATAFILE}"
		SELECT (time / 60) * 60, count(time)
		FROM mix
		WHERE txn = '${TXN_TAG}'
        GROUP BY 1
		ORDER BY 1;
	EOF
elif [ "${RATE}" = "tps" ]; then
	sqlite3 "${DBFILE}" <<- EOF > "${DATAFILE}"
		SELECT time, count(time)
		FROM mix
		WHERE txn = '${TXN_TAG}'
		GROUP BY time
		ORDER BY time;
	EOF
else
	echo "ERROR: unknown rate ${RATE}"
	exit 1
fi

gnuplot << EOF
datafile = "${DATAFILE}"
set datafile separator "|"
set xdata time
set timefmt "%s"
set terminal pngcairo size $SIZE
set xlabel "Time"
set xtics rotate
set xtics format "%R"
set grid
set title "${TXN_NAME} Transaction Rate" noenhanced
set output "${OUTPUTDIR}/t${TXN_TAG}-transaction-rate.png"
set ylabel "Transaction per ${YLABEL}"
set key off
plot datafile using 1:2 notitle with linespoints
EOF

 cleanup

 exit 0
