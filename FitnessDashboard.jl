using DataFrames
using DBInterface
using FunSQL
using FunSQL: From, Get, Group, Select, render, reflect
using Genie, Stipple, StippleUI
using Genie.Renderers.Html
using SQLite
using Stipple
using StipplePlotly
using StippleUI

db = DBInterface.connect(SQLite.DB, "exercise.db")
table_info = reflect(db).tables

weights = table_info[:weights]

weights_data =
    From(weights) |> FunSQL.render |> sql -> DBInterface.execute(db, sql) |> DataFrame

weights_data.WORKOUT_DATE = Dates.Date.(weights_data.WORKOUT_DATE)

pd(; x, y, name) =
    PlotData(x = x, y = y, plot = StipplePlotly.Charts.PLOT_TYPE_LINE, name = name)

export Model

@reactive mutable struct Model <: ReactiveModel
    plot_weight_data::R{Vector{PlotData}} = [
        pd(
            x = group.WORKOUT_DATE,
            y = group.WEIGHT .* group.REPS,
            name = first(group.EXERCISE),
        ) for group in groupby(weights_data, :EXERCISE)
    ]

    layout_weight_data::R{PlotLayout} = PlotLayout(
        title = PlotLayoutTitle(text = "Weight Lifted Over Year", font = Font(24)),
        xaxis = [PlotLayoutAxis(xy = "x", title_text = "Date")],
        yaxis = [PlotLayoutAxis(xy = "y", title_text = "Total Weight Lifted per Exercise")],
        showlegend = true,
    )

    config_weight_data::R{PlotConfig} = PlotConfig()

end

model = Model |> init

function ui(model)
    page(
        model,
        class = "container",
       
        list(bordered=true, separator=true, [
          
          item(clickable=true, vripple=true, [
            itemsection([
                plot(
                "{data}",
                layout = :layout_weight_data,
                config = :config_weight_data,
                )
            ])
          ], @recur(:"data in plot_weight_data"))
          
        ])
      
    )
end

route("/") do
    Stipple.init(Model) |> ui |> html
end