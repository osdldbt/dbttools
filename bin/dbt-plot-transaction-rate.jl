#!/bin/sh
#
# This file is released under the terms of the Artistic License.
# Please see the file LICENSE, included in this package, for details.
#
# Copyright (C) 2014      2ndQuadrant, Ltd.
#               2010-2023 Mark Wong
#

#=
if [ $# -lt 6 ]; then
	echo "$(basename $0) is the DBT transaction rate plotter"
	echo ""
	echo "Usage:"
	echo "  $(basename $0) <txn name> <txn id> <rate> <output directory> <color index> <log0> [log1 [...]]"
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

exec julia --color=no --startup-file=no "$0" "$@"
=#

using CSV
using DataFrames
using VegaLite

function load(filenames, params)
    colnames = [
            "ctime",
            "transaction",
            "code",
            "response_time",
            "id",
            "wid",
            "did",
    ]
    dfs = map(x -> CSV.File(x, header=colnames) |> DataFrame, filenames)
    df = reduce(vcat, dfs, cols=:union)

    # Convert ctime to elapsed time in minutes, in-place, and aggregate the
    # transaction response time per specified rate.

    start_time = minimum(df.ctime)
    df = df[df.transaction .== params["txn_tag"], [:ctime]]
    transform!(
            df,
            :ctime => ByRow(x -> ceil(Int, (x - start_time) / 60)) => :ctime
    )
    gdf = groupby(df, [:ctime]; sort=true)
    df = combine(gdf, nrow => :count)

    return df
end

function plot(df, params)
    p = df |>
        @vlplot(
            title=params["txn_name"] * " Transaction Rate",
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
                :count,
                title="Transactions per " * params["rate_unit"],
            },
        )
    filename = params["outputdir"] * "/t" * params["txn_tag"] *
               "-transaction-rate.png"
    save(filename, p)
end

function main()
    params = Dict(
            "txn_name" => ARGS[1],
            "txn_tag" => ARGS[2],
            "rate" => ARGS[3],
            "outputdir" => ARGS[4],
            "color" => ARGS[5],
    )

    if params["rate"] == "tpm"
        params["rate_unit"] = "Minute"
    elseif params["rate"] == "tps"
        params["rate_unit"] = "Second"
    else
        throw(DomainError(params["rate"], "this rate is unhandled"))
    end

    df = load(ARGS[6:end], params)
    plot(df, params)
end

main()
