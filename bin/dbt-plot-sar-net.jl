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
	echo "Create a plot of network statistics."
	echo "usage: $(basename "$0") <sar-net.csv> <output directory>"
	echo
	echo "    <sar-net.csv> - full path to the sar-net.csv file"
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
    interfaces = sort(unique(df.IFACE))
    for interface in interfaces
        sdf = df[df.IFACE .== interface, Not([:IFACE])]
        plot_interface(interface, sdf, params)
    end

    # Interface utilization.
    p = df |>
        @vlplot(
            title="Network Device Interface Utilization",
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
                field="%ifutil",
                title="% Utilization",
                scale={
                    domain=[0, 100],
                },
            },
            color={
                :IFACE,
                title="",
            },
        )
    filename = params["outputdir"] * "/sar-net-util.png"
    save(filename, p)
end

function plot_interface(interface, df, params)
    # Create a new dataframe and transform data for Vega-Lite for multi-series
    # line chart of data transmission rates.

    df_receive = df[!, ["timestamp", "rxkB/s"]]
    rename!(df_receive, ["timestamp", "kB/s"])
    insertcols!(df_receive, :label => "rxkB/s")

    df_transmit = df[!, ["timestamp", "txkB/s"]]
    rename!(df_transmit, ["timestamp", "kB/s"])
    insertcols!(df_transmit, :label => "txkB/s")

    df = vcat(df_receive, df_transmit)

    p = df |>
        @vlplot(
            title="Network Device " * interface * " Receive/Transmit",
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
                field="kB/s",
                title="KiloBytes/s",
            },
            color={
                :label,
                title="",
            },
        )
    filename = params["outputdir"] * "/sar-net-" * interface * "-x.png"
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
