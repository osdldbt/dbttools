#!/bin/sh
#
# This file is released under the terms of the Artistic License.
# Please see the file LICENSE, included in this package, for details.
#
# Copyright (C) 2015      Mark Wong
#               2015      2ndQuadrant, Ltd.
#

#=
INPUTFILE=$1
OUTPUTDIR=$2

if [ $# -ne 2 ]; then
	echo "Create a plot of swap statistics."
	echo "usage: $(basename "$0") <sar-swap.csv> <output directory>"
	echo
	echo "    <sar-swap.csv> - full path to the sar-net.csv file"
	echo "    <output directory> - location to write output files"
	echo
	echo "Will attempt to create <output directory> if it does not exist."
	exit 1
fi

exec julia --color=no --startup-file=no "$0" "$@"
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
    idf = df[!, ["timestamp", "pswpin/s"]]
    rename!(idf, ["timestamp", "pswp/s"])
    insertcols!(idf, :label => "pswpin/s")

    odf = df[!, ["timestamp", "pswpout/s"]]
    rename!(odf, ["timestamp", "pswp/s"])
    insertcols!(odf, :label => "pswpout/s")
    idf = vcat(idf, odf)

    p = idf |>
        @vlplot(
            title="Swap Activity",
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
                field="pswp/s",
                title="Pages/s",
            },
            color={
                :label,
                title="",
            },
        )
    filename = params["outputdir"] * "/sar-swap.png"
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
