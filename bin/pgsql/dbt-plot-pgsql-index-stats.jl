#!/bin/sh
#
# This file is released under the terms of the Artistic License.
# Please see the file LICENSE, included in this package, for details.
#
# Copyright (C) 2023 Mark Wong
#

#=
usage()
{
	echo "$(basename "$0") is the PostgreSQL index statistics chart generator"
	echo ""
	echo "Usage:"
	echo "  $(basename "$0") [OPTION]"
	echo ""
	echo "Options:"
	echo "  -i CSV      path to CSV file"
	echo "  -n INDEX    index name"
	echo "  -o PATH     output directory"
}

while getopts "hi:n:o:" opt; do
	case $opt in
	h)
		usage
		exit 1
		;;
	i)
		CSVFILE=$OPTARG
		;;
	n)
		INDEXNAME=$OPTARG
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

if [ "$CSVFILE" = "" ]; then
	error "ERROR: input CSV file was not specified with -i"
	exit 1
fi

if [ "$OUTDIR" = "" ]; then
	error "ERROR: output directory was not specified with -o"
	exit 1
fi

if [ "$INDEXNAME" = "" ]; then
	echo "ERROR: index name not set, use -n"
	exit 1
fi

exec julia --color=no --startup-file=no "$0" $CSVFILE $OUTDIR $INDEXNAME
=#

using CSV
using DataFrames
using VegaLite

function load(params)
    df = CSV.File(params["filename"]) |> DataFrame

    # Convert ctime to elapsed time in minutes, in-place.

    start_time = minimum(df.ctime)
    subset!(df,
            :indexrelname => ByRow(==(params["indexname"])); skipmissing=true)
    transform!(df, :ctime => ByRow(x -> (x - start_time) / 60) => :ctime)

    return df
end

function plot(df, params)
    # Recalculate change between samples.

    for row in reverse(2:nrow(df))
        df.idx_blks_hit[row] =
                df.idx_blks_hit[row] - df.idx_blks_hit[row - 1]
        df.idx_blks_read[row] =
                df.idx_blks_read[row] - df.idx_blks_read[row - 1]
        df.idx_scan[row] = df.idx_scan[row] - df.idx_scan[row - 1]
        df.idx_tup_fetch[row] =
                df.idx_tup_fetch[row] - df.idx_tup_fetch[row - 1]
        df.idx_tup_read[row] = df.idx_tup_read[row] - df.idx_tup_read[row - 1]
    end
    df.idx_blks_hit[1] = 0
    df.idx_blks_read[1] = 0
    df.idx_scan[1] = 0
    df.idx_tup_fetch[1] = 0
    df.idx_tup_read[1] = 0

    plot_index_stat(df, params, "idx_blks_read",
            "Index Blocks Read (" * params["indexname"] * ")", "Blocks")
    plot_index_stat(df, params, "idx_blks_hit",
            "Index Blocks Hit (" * params["indexname"] * ")", "Blocks")
    plot_index_stat(df, params, "idx_scan",
            "Index Scans (" * params["indexname"] * ")", "Scans")
    plot_index_stat(df, params, "idx_tup_fetch",
            "Tuples Fetched (" * params["indexname"] * ")", "Tuples")
    plot_index_stat(df, params, "idx_tup_read",
            "Tuples Read (" * params["indexname"] * ")", "Tuples")
end

function plot_index_stat(df, params, field, title, ylabel)
    p = df |>
        @vlplot(
            title=title,
            width=1200,
            height=800,
            mark={
                type="line",
                point=true,
            },
            x={
                :ctime,
                title="Elapsed Time (minutes)",
            },
            y={
                field=field,
                title=ylabel,
            },
            color={
                :schemaname,
                title="Schema",
            },
        )
    filename = params["outputdir"] * "/index-stat-" * params["indexname"] *
            "-" * field * ".png"
    save(filename, p)
end

function main()
    params = Dict(
            "filename" => ARGS[1],
            "outputdir" => ARGS[2],
            "indexname" => ARGS[3],
    )

    df = load(params)
    plot(df, params)
end

main()
