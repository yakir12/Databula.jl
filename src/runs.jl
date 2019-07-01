using DataStructures 

getrun() = loadtable(run_file_name, indexcols = :run)

function getdate()
    @label askdatetime
    println("Specify a date for this run\n[Enter: $(defaults[:date])]")
    _dt = strip(readline(stdin))
    dt = isempty(_dt) ? defaults[:datetime] : tryparsedatetime(_dt)
    if dt ≡ nothing
        @warn "the format of the date is wrong, try something like:" Date(now())
        @goto askdatetime
    end
    defaults[:date] = dt
    dt
end


function register_run()
    cdata = OrderedDict(k => "" for k in COMMON_FACTORS)
    run = getrun()
    experiment = getexperiment()
    cdata[:run] = uuid4()
    options = select(experiment, :experiment)
    defaults[:experiment] = first(select(experiment, :experiment))
    pushfirst!(options, defaults[:experiment])
    menu = RadioMenu(options)
    i = request("To which experiment does this run belong to?", menu)
    if i == 1
        i = findlast(isequal(menu.options[1]), menu.options)
    end
    cdata[:experiment] = experiment[i - 1].experiment
    cdata[:date] = getdate()
    println("Any comments about this run:")
    cdata[:comment] = strip(readline(stdin))
    println("Who was the experimenter?\n[Enter: $(defaults[:person])]")
    _person = strip(readline(stdin))
    cdata[:person] = isempty(_person) ? defaults[:person] : _person
    defaults[:person] = person
    data = OrderedDict(k => "" for k in FACTORS)
    for factor in FACTORS
        println("Specify $factor")
    _level = strip(readline(stdin))
    data[:factor] = isempty(_person) ? defaults[:person] : _person
    defaults[:person] = person
        data[factor] = strip(readline(stdin))
    end
    [(; cdata..., data...)] |> CSV.write(run_file_name, append = true)
end

