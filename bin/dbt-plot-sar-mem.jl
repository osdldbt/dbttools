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
	echo "$(basename "$0") is the DBT sar memory statistics chart generator"
	echo ""
	echo "Usage:"
	echo "  $(basename "$0") [OPTION]"
	echo ""
	echo "Options:"
	echo "  -i CSV      path to sar-mem.csv file"
	echo "  -o PATH     output directory"
}

while getopts "hi:o:" opt; do
	case $opt in
	h)
		usage
		exit 1
		;;
	i)
		INPUTFILE=$OPTARG
		;;
	o)
		OUTDIR=$OPTARG
		mkdir -p "$OUTDIR"
		if [ ! -d "$OUTDIR" ]; then
			echo "ERROR: Failed to create directory $OUTDIR"
			exit 1
		fi
		;;
	\?)
		usage
		exit 1
		;;
	esac
done

if [ "$INPUTFILE" = "" ]; then
	error "ERROR: input CSV file was not specified with -i"
	exit 1
fi

if [ "$OUTDIR" = "" ]; then
	error "ERROR: output directory was not specified with -o"
	exit 1
fi

exec julia --color=no --startup-file=no "$0" "$INPUTFILE" "$OUTDIR"
=#

using CSV
using DataFrames
using VegaLite

function load(params)
    df = CSV.File(params["filename"]) |> DataFrame

    # Convert timestamp to elapsed time in minutes, in-place.

    start_time = minimum(df.timestamp)
    df = df[!, Not(["# hostname", "interval"])]
    transform!(
            df,
            :timestamp => ByRow(x -> (x - start_time) / 60) => :timestamp;
    )

    return df
end

function plot(df, params)
    p = df |>
        @vlplot(
            title="Buffered Kernel Memory",
            width=1200,
            height=800,
            mark={
                type="line",
                point=true,
            },
            x={
                :timestamp,
                title="Elapsed Time (minutes)",
            },
            y={
                field=:kbbuffers,
                title="KiloBytes",
            },
        )
    filename = params["outputdir"] * "/sar-mem-kbbuffers.png"
    save(filename, p)

    p = df |>
        @vlplot(
            title="Cached Kernel Memory",
            width=1200,
            height=800,
            mark={
                type="line",
                point=true,
            },
            x={
                :timestamp,
                title="Elapsed Time (minutes)",
            },
            y={
                field=:kbcached,
                title="KiloBytes",
            },
        )
    filename = params["outputdir"] * "/sar-mem-kbcached.png"
    save(filename, p)

    p = df |>
        @vlplot(
            title="Dirty Memory",
            width=1200,
            height=800,
            mark={
                type="line",
                point=true,
            },
            x={
                :timestamp,
                title="Elapsed Time (minutes)",
            },
            y={
                field=:kbdirty,
                title="KiloBytes",
            },
        )
    filename = params["outputdir"] * "/sar-mem-kbdirty.png"
    save(filename, p)

    p = df |>
        @vlplot(
            title="Memory Utilization",
            width=1200,
            height=800,
            mark={
                type="line",
                point=true,
            },
            x={
                :timestamp,
                title="Elapsed Time (minutes)",
            },
            y={
                field="%memused",
                title="% Memory Used",
                scale={
                    domain=[0, 100],
                },
            },
        )
    filename = params["outputdir"] * "/sar-mem-memused.png"
    save(filename, p)
end

function main()
    params = Dict(
            "filename" => ARGS[1],
            "outputdir" => ARGS[2],
    )

    df = load(params)
    plot(df, params)
end

main()
