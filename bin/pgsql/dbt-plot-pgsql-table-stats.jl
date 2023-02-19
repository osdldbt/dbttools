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
	echo "$(basename "$0") is the PostgreSQL table statistics chart generator"
	echo ""
	echo "Usage:"
	echo "  $(basename "$0") [OPTION]"
	echo ""
	echo "Options:"
	echo "  -i CSV      path to CSV file"
	echo "  -n TABLE    table name"
	echo "  -o PATH     output directory"
}

error() {
	echo "ERROR: $*"
	exit 1
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
		TABLENAME=$OPTARG
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
	error "input CSV file was not specified with -i"
fi

if [ "$OUTDIR" = "" ]; then
	error "output directory was not specified with -o"
fi

if [ "$TABLENAME" = "" ]; then
	error "table name not set, use -n"
fi

exec julia --color=no --startup-file=no "$0" $CSVFILE $OUTDIR $TABLENAME
=#

using CSV
using DataFrames
using VegaLite

function load(params)
    df = CSV.File(params["filename"]) |> DataFrame

    # Convert ctime to elapsed time in minutes, in-place.

    start_time = minimum(df.ctime)
    subset!(df, :relname => ByRow(==(params["relname"])); skipmissing=true)
    transform!(df, :ctime => ByRow(x -> (x - start_time) / 60) => :ctime)

    return df
end

function plot(df, params)
    # Recalculate change between samples.

    for row in reverse(2:nrow(df))
        df.heap_blks_hit[row] =
                df.heap_blks_hit[row] - df.heap_blks_hit[row - 1]
        df.heap_blks_read[row] =
                df.heap_blks_read[row] - df.heap_blks_read[row - 1]
        df.idx_blks_hit[row] =
                df.idx_blks_hit[row] - df.idx_blks_hit[row - 1]
        df.idx_blks_read[row] =
                df.idx_blks_read[row] - df.idx_blks_read[row - 1]
        df.idx_scan[row] = df.idx_scan[row] - df.idx_scan[row - 1]
        df.idx_tup_fetch[row] =
                df.idx_tup_fetch[row] - df.idx_tup_fetch[row - 1]
        df.n_dead_tup[row] = df.n_dead_tup[row] - df.n_dead_tup[row - 1]
        df.n_live_tup[row] = df.n_live_tup[row] - df.n_live_tup[row - 1]
        df.n_tup_del[row] = df.n_tup_del[row] - df.n_tup_del[row - 1]
        df.n_tup_hot_upd[row] =
                df.n_tup_hot_upd[row] - df.n_tup_hot_upd[row - 1]
        df.n_tup_ins[row] = df.n_tup_ins[row] - df.n_tup_ins[row - 1]
        df.n_tup_upd[row] = df.n_tup_upd[row] - df.n_tup_upd[row - 1]
        df.seq_scan[row] = df.seq_scan[row] - df.seq_scan[row - 1]
        df.seq_tup_read[row] = df.seq_tup_read[row] - df.seq_tup_read[row - 1]
        df.tidx_blks_hit[row] =
                df.tidx_blks_hit[row] - df.tidx_blks_hit[row - 1]
        df.tidx_blks_read[row] =
                df.tidx_blks_read[row] - df.tidx_blks_read[row - 1]
        df.toast_blks_hit[row] =
                df.toast_blks_hit[row] - df.toast_blks_hit[row - 1]
        df.toast_blks_read[row] =
                df.toast_blks_read[row] - df.toast_blks_read[row - 1]
    end
    df.heap_blks_hit[1] = 0
    df.heap_blks_read[1] = 0
    df.idx_blks_hit[1] = 0
    df.idx_blks_read[1] = 0
    df.idx_scan[1] = 0
    df.idx_tup_fetch[1] = 0
    df.n_dead_tup[1] = 0
    df.n_live_tup[1] = 0
    df.n_tup_del[1] = 0
    df.n_tup_hot_upd[1] = 0
    df.n_tup_ins[1] = 0
    df.n_tup_upd[1] = 0
    df.seq_scan[1] = 0
    df.seq_tup_read[1] = 0
    df.tidx_blks_hit[1] = 0
    df.tidx_blks_read[1] = 0
    df.toast_blks_hit[1] = 0
    df.toast_blks_read[1] = 0

    plot_table_stat(df, params, "head_blks_hit",
            "Heap Blocks Hit (" * params["relname"] * ")", "Blocks")
    plot_table_stat(df, params, "head_blks_read",
            "Heap Blocks Read (" * params["relname"] * ")", "Blocks")
    plot_table_stat(df, params, "idx_blks_hit",
            "Index Blocks Hit (" * params["relname"] * ")", "Blocks")
    plot_table_stat(df, params, "idx_blks_read",
            "Index Blocks Read (" * params["relname"] * ")", "Blocks")
    plot_table_stat(df, params, "idx_scan",
            "Index Scans (" * params["relname"] * ")", "Index Scans")
    plot_table_stat(df, params, "n_tup_del",
            "Deletes (" * params["relname"] * ")", "Tuples")
    plot_table_stat(df, params, "n_tup_hot_upd",
            "HOT Updates(" * params["relname"] * ")", "Tuples")
    plot_table_stat(df, params, "n_dead_tup",
            "Estimated Number of Dead Rows (" * params["relname"] * ")",
            "Tuples")
    plot_table_stat(df, params, "n_live_tup",
            "Live Rows (" * params["relname"] * ")", "Tuples")
    plot_table_stat(df, params, "n_tup_ins",
            "Inserts (" * params["relname"] * ")", "Tuples")
    plot_table_stat(df, params, "n_tup_upd",
            "Updates (" * params["relname"] * ")", "Tuples")
    plot_table_stat(df, params, "seq_scan",
            "Sequential Scans (" * params["relname"] * ")", "Sequential Scans")
    plot_table_stat(df, params, "seq_tup_read",
            "Tuples Read by Sequential Scans (" * params["relname"] * ")",
            "Tuples")
    plot_table_stat(df, params, "tidx_blks_hit",
            "Toast Index Blocks Hit (" * params["relname"] * ")", "Blocks")
    plot_table_stat(df, params, "tidx_blks_read",
            "Toast Index Blocks Read (" * params["relname"] * ")", "Blocks")
    plot_table_stat(df, params, "toast_blks_hit",
            "Toast Blocks Hit (" * params["relname"] * ")", "Blocks")
    plot_table_stat(df, params, "toast_blks_read",
            "Toast Blocks Read (" * params["relname"] * ")", "Blocks")


    sdf = df[!, [:ctime, :seq_tup_read]]
    rename!(sdf, [:ctime, :tuples])
    insertcols!(sdf, :label => "Sequential Scans")

    ndf = df[!, [:ctime, :idx_tup_fetch]]
    rename!(ndf, [:ctime, :tuples])
    insertcols!(ndf, :label => "Index Scans")
    sdf = vcat(sdf, ndf)

    ndf = df[!, [:ctime, :n_tup_ins]]
    rename!(ndf, [:ctime, :tuples])
    insertcols!(ndf, :label => "Inserts")
    sdf = vcat(sdf, ndf)

    ndf = df[!, [:ctime, :n_tup_upd]]
    rename!(ndf, [:ctime, :tuples])
    insertcols!(ndf, :label => "Updates")
    sdf = vcat(sdf, ndf)

    ndf = df[!, [:ctime, :n_tup_del]]
    rename!(ndf, [:ctime, :tuples])
    insertcols!(ndf, :label => "Deletes")
    sdf = vcat(sdf, ndf)

    ndf = df[!, [:ctime, :n_tup_hot_upd]]
    rename!(ndf, [:ctime, :tuples])
    insertcols!(ndf, :label => "HOT Updates")
    sdf = vcat(sdf, ndf)

    p = sdf |>
        @vlplot(
            title="Tuples (" * params["relname"] * ")",
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
                :tuples,
                title="Tuples",
            },
            color={
                :label,
                title="",
            },
        )
    filename = params["outputdir"] * "/table-stat-" * params["relname"] *
            "-tup.png"
    save(filename, p)
end

function plot_table_stat(df, params, field, title, ylabel)
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
    filename = params["outputdir"] * "/table-stat-" * params["relname"] * "-" *
            field * ".png"
    save(filename, p)
end

function main()
    params = Dict(
            "filename" => ARGS[1],
            "outputdir" => ARGS[2],
            "relname" => ARGS[3],
    )

    df = load(params)
    plot(df, params)
end

main()
