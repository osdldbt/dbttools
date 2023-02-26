#!/bin/sh
#
# This file is released under the terms of the Artistic License.
# Please see the file LICENSE, included in this package, for details.
#
# Copyright The DBT Tools Authors
#

#=
usage()
{
	echo "$(basename "$0") is the PostgreSQL database statistics chart generator"
	echo ""
	echo "Usage:"
	echo "  $(basename "$0") [OPTION]"
	echo ""
	echo "Options:"
	echo "  -i CSV      path to CSV file"
	echo "  -n DBNAME   database name"
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
		PGDATABASE=$OPTARG
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

if [ "$PGDATABASE" = "" ]; then
	echo "ERROR: PGDATABASE not set, use -n"
	exit 1
fi

exec julia --color=no --startup-file=no "$0" $CSVFILE $OUTDIR $PGDATABASE
=#

using CSV
using DataFrames
using VegaLite

function load(params)
    df = CSV.File(params["filename"]) |> DataFrame

    # Convert ctime to elapsed time in minutes, in-place.

    start_time = minimum(df.ctime)
    subset!(df, :datname => ByRow(==(params["dbname"])); skipmissing=true)
    transform!(df, :ctime => ByRow(x -> (x - start_time) / 60) => :ctime)

    return df
end

function plot(df, params)
    p = df |>
        @vlplot(
            title="Database " * params["dbname"] * " Number of Backends",
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
                :numbackends,
                title="Backends",
            },
        )
    filename = params["outputdir"] * "/db-stat-" * params["dbname"] *
               "-connections.png"
    save(filename, p)

    cdf = df[!, [:ctime, :xact_commit]]
    rename!(cdf, [:ctime, :xact])
    insertcols!(cdf, :label => "Commits")

    rdf = df[!, [:ctime, :xact_rollback]]
    rename!(rdf, [:ctime, :xact])
    insertcols!(rdf, :label => "Rollbacks")
    cdf = vcat(cdf, rdf)

    p = cdf |>
        @vlplot(
            title="Database " * params["dbname"] * " Transactions",
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
                :xact,
                title="",
            },
            color={
                :label,
                title="",
            },
        )
    filename = params["outputdir"] * "/db-stat-" * params["dbname"] *
               "-xacts.png"
    save(filename, p)

    rdf = df[!, [:ctime, :blks_read]]
    rename!(rdf, [:ctime, :blks])
    insertcols!(rdf, :label => "Read")

    hdf = df[!, [:ctime, :blks_hit]]
    rename!(hdf, [:ctime, :blks])
    insertcols!(hdf, :label => "Hit")
    rdf = vcat(rdf, hdf)

    p = rdf |>
        @vlplot(
            title="Database " * params["dbname"] * " Blocks",
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
                :blks,
                title="Blocks",
            },
            color={
                :label,
                title="",
            },
        )
    filename = params["outputdir"] * "/db-stat-" * params["dbname"] *
               "-blocks.png"
    save(filename, p)
end

function main()
    params = Dict(
            "filename" => ARGS[1],
            "outputdir" => ARGS[2],
            "dbname" => ARGS[3],
    )

    df = load(params)
    plot(df, params)
end

main()
