#!/bin/sh
#
# This file is released under the terms of the Artistic License.
# Please see the file LICENSE, included in this package, for details.
#
# Copyright The DBT Tools Authors
#

SIZE="1600,1000"

error() {
	echo "ERROR: $*" >&2
	exit 1
}

# Only remove paths this script created.  The trap is in place before
# DATAFILE is assigned, so an empty value means there is nothing to do.
# shellcheck disable=SC2317  # invoked by the EXIT trap below
cleanup() {
	if [ -n "${DATAFILE}" ]; then
		rm -f "${DATAFILE}"
	fi
}

# Clean up on every exit path, including the error exits below.  The
# signal handlers only exit: that runs the EXIT trap, which does the
# removal, so there is exactly one cleanup path.
trap cleanup EXIT
trap 'exit 1' HUP INT QUIT ABRT TERM

if [ $# -lt 5 ]; then
	echo "$(basename "${0}") is the DBT transaction distribution plotter"
	echo ""
	echo "Usage:"
	echo "  $(basename "${0}") <txn name> <txn id> <output directory> <color index> <log0> [log1 [...]]"
	echo ""
	echo "Options"
	echo "  txn name            name to use on the chart title"
	echo "  txn id              identifier used in the log file"
	echo "  output directory    path to output charts"
	echo "  color index         number for selecting plot color"
	echo "  log                 log file to load"
	exit 1
fi

TXN_NAME=$1
shift
TXN_TAG=$1
shift
OUTPUTDIR=$1
shift
# TODO: Handle color.
shift

mkdir -p "${OUTPUTDIR}"
if [ ! -d "${OUTPUTDIR}" ]; then
	error "Failed to create directory ${OUTPUTDIR}"
fi

DATAFILE=$(mktemp)

# Use the earliest event in any of the logs as time zero, per the R and
# Julia versions of this script.
START=$(awk -F ',' \
		'START == "" || $1 < START {START = $1} END {print START}' \
		"${@}")

for FILENAME in "${@}"; do
	awk -F ',' -v TXN="${TXN_TAG}" -v START="${START}" \
			'$2 == TXN {print ($1 - START) / 60, $4}' \
			"${FILENAME}" >> "${DATAFILE}"
done

if [ ! -s "${DATAFILE}" ]; then
	error "no ${TXN_TAG} transactions found in the logs"
fi

gnuplot << EOF
datafile = "${DATAFILE}"
set terminal pngcairo size $SIZE
set xlabel "Elapsed Time (minutes)"
set grid
set title "${TXN_NAME} Transaction Response Time Distribution" noenhanced
set output "${OUTPUTDIR}/t${TXN_TAG}-distribution.png"
set ylabel "Response Time (seconds)"
set key off
plot datafile using 1:2 notitle with points
EOF
