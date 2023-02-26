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
	echo "usage: $(basename "$0") <sar-cpu.csv> <output directory>"
	echo
	echo "    <sar-cpu.csv> - full path to the sar-cpu.csv file"
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
    udf = df[df.CPU .== -1, ["timestamp", "%user"]]
    rename!(udf, ["timestamp", "%"])
    insertcols!(udf, :label => "user")

    sdf = df[df.CPU .== -1, ["timestamp", "%system"]]
    rename!(sdf, ["timestamp", "%"])
    insertcols!(sdf, :label => "system")
    udf = vcat(udf, sdf)

    odf = df[df.CPU .== -1, ["timestamp", "%iowait"]]
    rename!(odf, ["timestamp", "%"])
    insertcols!(odf, :label => "iowait")
    udf = vcat(udf, odf)

    idf = df[df.CPU .== -1, ["timestamp", "%idle"]]
    rename!(idf, ["timestamp", "%"])
    insertcols!(idf, :label => "idle")
    udf = vcat(udf, idf)

    p = udf |>
        @vlplot(
            title="Aggregated Processor Utilization",
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
                field="%",
                title="% Utilization",
                scale={
                    domain=[0, 100],
                },
            },
            color={
                :label,
                title="",
            },
        )
    filename = params["outputdir"] * "/sar-cpu.png"
    save(filename, p)

    df = df[df.CPU .!= -1, :]
    transform!(df, "%idle" => ByRow(x -> 100.0 - x) => :busy)
    p = df |>
        @vlplot(
            title="Processor Utilization",
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
                field=:busy,
                title="% Busy",
                scale={
                    domain=[0, 100],
                },
            },
            color={
                :CPU,
            },
        )
    filename = params["outputdir"] * "/sar-cpu-all.png"
    save(filename, p)

    cpus = sort(unique(df.CPU))
    for cpu in cpus
        sdf = df[df.CPU .== cpu, :]
        plot_cpu(cpu, sdf, params)
    end
end

function plot_cpu(cpu, df, params)
    udf = df[!, ["timestamp", "%user"]]
    rename!(udf, ["timestamp", "%"])
    insertcols!(udf, :label => "user")

    sdf = df[!, ["timestamp", "%system"]]
    rename!(sdf, ["timestamp", "%"])
    insertcols!(sdf, :label => "system")
    udf = vcat(udf, sdf)

    odf = df[!, ["timestamp", "%iowait"]]
    rename!(odf, ["timestamp", "%"])
    insertcols!(odf, :label => "iowait")
    udf = vcat(udf, odf)

    idf = df[!, ["timestamp", "%idle"]]
    rename!(idf, ["timestamp", "%"])
    insertcols!(idf, :label => "idle")
    udf = vcat(udf, idf)

    p = udf |>
        @vlplot(
            title="CPU " * string(cpu) * " Processor Utilization",
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
                field="%",
                title="% Utilization",
                scale={
                    domain=[0, 100],
                },
            },
            color={
                :label,
                title="",
            },
        )
    filename = params["outputdir"] * "/sar-cpu" * string(cpu) * ".png"
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
