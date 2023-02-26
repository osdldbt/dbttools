#!/bin/sh
#
# This file is released under the terms of the Artistic License.
# Please see the file LICENSE, included in this package, for details.
#
# Copyright The DBT Tools Authors
#

#=
INPUTFILE=$1
OUTPUTDIR=$2

if [ $# -ne 2 ]; then
	echo "Create a plot the rate of transactions."
	echo "usage: $(basename "$0") <sar-blockdev.csv> <output directory>"
	echo
	echo "    <sar-blockdev.csv> - full path to the sar-blockdev.csv file"
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
    p = df |>
        @vlplot(
            title="Block Device Utilization",
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
                field="%util",
                title="% Utilization",
                scale={
                    domain=[0, 100],
                },
            },
            color={
                :DEV,
                title="Block Device",
            },
        )
    filename = params["outputdir"] * "/sar-blockdev-util.png"
    save(filename, p)

    p = df |>
        @vlplot(
            title="Transfer per Second",
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
                field=:tps,
                title="",
            },
            color={
                :DEV,
                title="Block Device",
            },
        )
    filename = params["outputdir"] * "/sar-blockdev-tps.png"
    save(filename, p)

    p = df |>
        @vlplot(
            title="Average Wait",
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
                field=:await,
                title="Milliseconds",
            },
            color={
                :DEV,
                title="Block Device",
            },
        )
    filename = params["outputdir"] * "/sar-blockdev-await.png"
    save(filename, p)

    p = df |>
        @vlplot(
            title="Average Queue Length",
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
                field="aqu-sz",
                title="",
            },
            color={
                :DEV,
                title="Block Device",
            },
        )
    filename = params["outputdir"] * "/sar-blockdev-avgqu.png"
    save(filename, p)

    p = df |>
        @vlplot(
            title="Average Request Size",
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
                field="areq-sz",
                title="Sectors",
            },
            color={
                :DEV,
                title="Block Device",
            },
        )
    filename = params["outputdir"] * "/sar-blockdev-areq.png"
    save(filename, p)

    devs = sort(unique(df.DEV))
    for dev in devs
        sdf = df[df.DEV .== dev, ["timestamp", "rkB/s", "wkB/s"]]
        plot_dev(dev, sdf, params)
    end
end

function plot_dev(dev, df, params)
    rdf = df[!, ["timestamp", "rkB/s"]]
    rename!(rdf, ["timestamp", "mB/s"])
    insertcols!(rdf, :label => "Reads")

    wdf = df[!, ["timestamp", "wkB/s"]]
    rename!(wdf, ["timestamp", "mB/s"])
    insertcols!(wdf, :label => "Writes")
    rdf = vcat(rdf, wdf)
    transform!(rdf, "mB/s" => ByRow(x -> x / 1024.0) => "mB/s")

    p = rdf |>
        @vlplot(
            title="Block Device " * dev * " Read/Write",
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
                field="mB/s",
                title="MegaBytes/s",
            },
            color={
                :label,
                title="",
            },
        )
    filename = params["outputdir"] * "/sar-blockdev-" * dev * "-rw.png"
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
