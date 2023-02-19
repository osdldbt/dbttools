#!/bin/sh
#
# This file is released under the terms of the Artistic License.
# Please see the file LICENSE, included in this package, for details.
#
# Copyright (C) 2015      2ndQuadrant, Ltd.
#               2015-2023 Mark Wong
#

#=
usage()
{
	echo "$(basename "$0") is the DBT pidstat plotter"
	echo ""
	echo "Usage:"
	echo "  $(basename "$0") [OPTIONS]"
	echo ""
	echo "General options:"
	echo "  -c COMMAND    command string to match"
	echo "  -i FILE       pidstat.csv file"
	echo "  -m METRIC     metric to plot"
	echo "  -i PATH       output directory, default ./"
	echo "  -t TAG        tag to use for chart filenames"
}

OUTDIR="."
while getopts "c:hi:m:o:t:" opt; do
	case $opt in
	c)
		COMMAND=$OPTARG
		;;
	h)
		usage
		exit 1
		;;
	i)
		INPUTFILE=$OPTARG
		;;
	m)
		METRIC=$OPTARG
		;;
	o)
		OUTDIR=$OPTARG
		if [ ! -d "$OUTDIR" ]; then
			mkdir -p "$OUTDIR"
		fi
		;;
	t)
		TAG="-${OPTARG}"
		;;
	*)
		usage
		exit 1
	esac
done

if [ "${INPUTFILE}" = "" ]; then
	echo "ERROR: use -i to specify pidstat csv file"
	exit 1
fi

if [ ! -f "${INPUTFILE}" ]; then
echo "ERROR: file does not exist ${INPUTFILE}"
	exit 1
fi

if [ "${METRIC}" = "" ]; then
	echo "ERROR: use -m to specify metric to plot"
	exit 1
fi

if [ "${COMMAND}" = "" ]; then
	echo "ERROR: use -c to specify command to plot"
	exit 1
fi

exec julia --color=no --startup-file=no "$0" $INPUTFILE $COMMAND $METRIC $TAG $OUTDIR
=#

using CSV
using DataFrames
using VegaLite

function load(params)
    df = CSV.File(params["filename"]) |> DataFrame

    # Convert ctime to elapsed time in minutes, in-place.

    start_time = minimum(df.Time)
    filter!(row->any(occursin.(params["command"], row.Command)), df)
    df = df[:, ["Time", params["metric"]]]
    transform!(
            df,
            :Time => ByRow(x -> ceil(Int, (x - start_time) / 60)) => :Time
    )

    return df
end

function plot(df, params)
    p = df |>
        @vlplot(
            title="pidstat " * params["metric"] * " " * params["command"],
            width=1200,
            height=800,
            mark={
                type="line",
                point=true,
            },
            x={
                :Time,
                title="Elapsed Time (minutes)",
            },
            y={
                field=params["metric"],
            },
        )
    # Mimic what R does with character replacement to make filenames easy to
    # handle.
    metric = replace(params["metric"], "%" => "X.", "/" => ".")
    filename = params["outputdir"] * "/pidstat" * params["tag"] * "-" *
               metric * ".png"
    save(filename, p)
end

function main()
    params = Dict(
            "filename" => ARGS[1],
            "command" => ARGS[2],
            "metric" => ARGS[3],
            "tag" => ARGS[4],
            "outputdir" => ARGS[5],
    )

    df = load(params)
    plot(df, params)
end

main()
