#!/bin/sh
#
# This file is released under the terms of the Artistic License.
# Please see the file LICENSE, included in this package, for details.
#
# Copyright The DBT Tools Authors
#

#=
if [ $# -lt 5 ]; then
	echo "$(basename "$0") is the DBT transaction distribution plotter"
	echo ""
	echo "Usage:"
	echo "  $(basename "$0") <txn name> <txn id> <output directory> <color index> <log0> [log1 [...]]"
	echo ""
	echo "Options"
	echo "  txn name            name to use on the chart title"
	echo "  txn id              identifier used in the log file"
	echo "  output directory    path to output charts"
	echo "  color index         number for selecting plot color"
	echo "  log                 log file to load"
	exit 1
fi

exec julia --color=no --startup-file=no "$0" "$@"
=#

using CSV
using DataFrames
using Statistics
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
    df = df[df.transaction .== params["txn_tag"], [:ctime, :response_time]]
    transform!(
            df,
            :ctime => ByRow(x -> (x - start_time) / 60) => :ctime
    )

    return df
end

function plot(df, params)
    p = df |>
        @vlplot(
            title=params["txn_name"] *
                  " Transaction Response Time Distribution",
            width=1200,
            height=800,
            mark={
                type="point",
            },
            x={
                :ctime,
                title="Elapsed Time (minutes)",
            },
            y={
                :response_time,
                title="Response Time (seconds)"
            },
        )
    filename = params["outputdir"] * "/t" * params["txn_tag"] *
               "-distribution.png"
    save(filename, p)
end

function main()
    params = Dict(
            "txn_name" => ARGS[1],
            "txn_tag" => ARGS[2],
            "outputdir" => ARGS[3],
            "color" => ARGS[4],
    )

    df = load(ARGS[5:end], params)
    plot(df, params)
end

main()
