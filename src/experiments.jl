getexperiment() = loadtable(experiment_file_name, indexcols = :experiment)

function register_experiment()
    experiment = getexperiment()
    @label startname
    println("Give a descriptive and unique name for the experiment")
    name = strip(readline(stdin))
    if isempty(name)
        @warn "The experiment must have a name"
        @goto startname
    end
    if name ∈ select(experiment, :experiment)
        @warn "You have already registered an experiment with that name:" select(experiment, :experiment)
        @goto startname
    end
    @label startdescription
    println("Describe the experiment as best you can")
    description = strip(readline(stdin))
    if isempty(description)
        @warn "The experiment must have a description"
        @goto startdescription
    end
    [(experiment = name, experiment_description = description)] |> CSV.write(experiment_file_name, append = true)
end

