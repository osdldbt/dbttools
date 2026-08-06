#!/bin/sh
#
# This file is released under the terms of the Artistic License.
# Please see the file LICENSE, included in this package, for details.
#
# Copyright The DBT Tools Authors
#

#=
if [ $# -lt 6 ]; then
	echo "$(basename "$0") is the DBT transaction rate plotter"
	echo ""
	echo "Usage:"
	echo "  $(basename "$0") <txn name> <txn id> <rate> <output directory> <color index> <log0> [log1 [...]]"
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
    duration = maximum(df.ctime) - start_time + 1
    df = df[df.transaction .== params["txn_tag"], [:ctime]]
    if nrow(df) == 0
        println(stderr, "ERROR: no " * params["txn_tag"] *
                        " transactions found in the logs")
        exit(1)
    end
    transform!(
            df,
            :ctime => ByRow(x -> div(x - start_time, 60)) => :ctime
    )
    gdf = groupby(df, [:ctime]; sort=true)
    df = combine(gdf, nrow => :count)

    # A tpm chart plots the per-minute counts directly; a tps chart
    # averages each minute over the seconds it actually covers.
    if params["rate"] == "tps"
        df.count = df.count ./ min.(60, duration .- df.ctime .* 60)
    end

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
                scale={zero=true},
            },
            y={
                :count,
                title="Transactions per " * params["rate_unit"],
                scale={zero=true},
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

    mkpath(params["outputdir"])

    df = load(ARGS[6:end], params)
    plot(df, params)
end

main()
