
function parse_and_scrape_folder(dir)
    fs = []
    for (root, dirs, files) in walkdir(dir)
		
        for file in files
            if endswith(file, ".jl")
                push!(fs, (root, file) )
            end          
        end
    end

    fsd = Array{FileDef, 1}(undef, length(fs))
    for i in 1:length(fs)
        println("#### HANDLING FILE $(fs[i][2]) ####")
        fsd[i] = handleFile(fs[i][1], fs[i][2])
    end
    fsd
end


function _handleExprArr(prs::Array{CSTParser.EXPR,1})
    #println("type of prs is $(typeof(prs))")
    includes = []
    uses = []
    modules = []
    functions = []
    _docs = nothing
    #docfind = false
    _docfind = false
    
    for expr in prs
        
        tmp = _genericScrape(expr)#=
        # this would be better as match case
        tincludes, tuses, tmodules, tfunctions = _parseHandler(tmp, docfind)
        includes = vcat(includes, tincludes)
        uses = vcat(uses, tuses)
        modules = vcat(modules, tmodules)
        functions = vcat(functions, tfunctions)
        tmp = nothing=#
        _setDocs = false
        tincludes, tuses, tmodules, tfunctions, tdocs, tdf = _parseHandler(tmp, _docfind)
        _docfind = tdf
        if !isnothing(tincludes)
            if !isnothing(_docs)
                setDocs!(tincludes, _docs)
                _setDocs = true
            end
            if isnothing(includes) # tdocs
                includes = tincludes
            else
                includes = vcat(includes, tincludes)
            end
        end
        if !isnothing(tuses)
            if !isnothing(_docs)
                setDocs!(tuses, _docs)
                _setDocs = true
            end
            if isnothing(uses)
                uses = tuses
            else
                uses = vcat(uses, tuses)
            end
        end
        if !isnothing(tmodules)
            if !isnothing(_docs)
                setDocs!(tmodules, _docs)
                _setDocs = true
            end
            if isnothing(modules)
                modules = tmodules
            else
                modules = vcat(modules, tmodules)
            end
        end
        if !isnothing(tfunctions)
            #tfunctions = [FunctionContainer(x,x.docs, "") for x in tfunctions] why did i ever do this
            if !isnothing(_docs)
                setDocs!(tfunctions, _docs)
                _setDocs = true
            end
            if isnothing(functions)
                functions = tfunctions
            else
                functions = vcat(functions, tfunctions)
            end                
        end

        if _setDocs
            _docs = nothing
            _setDocs = false
        end
        
        if !isnothing(tdocs)
            _docs = tdocs
        end
    end
    includes, uses, modules, functions
end



function handleFile(folder::String, file::String)
    path = joinpath(folder, file)
    #println("parsing...")
    prs = CSTParser.parse(read(joinpath(folder, file), String), true)
    #println("handling...")
    if _checkArgs(prs)
        includes, uses, modules, functions = _handleExprArr(prs.args) 
        #println("generating FileDef...")
        FileDef(path, uses, modules, functions, includes)
    else
        FileDef()
    end

end

function _parseHandler(tuple, docfind)
    if isnothing(tuple)
        tuple = ("","")
    end
    includes = nothing
    uses = nothing
    modules = nothing
    functions = nothing
    docs = nothing
    tmp = tuple
    # this would be better as match case
    if tmp[1] == "include"
        includes = [tmp[2]]
    elseif tmp[1] == "using"
        uses = tmp[2]
    elseif tmp[1] == "module"
        modules= [ tmp[2]]
    elseif tmp[1] == "function"
        functions = [tmp[2]]
    elseif tmp[1] == "macrocall"
        _docfind = false
        _docs = nothing
        _setDocs = false
        for elem in tmp[2]           
            tincludes, tuses, tmodules, tfunctions, tdocs, tdf = _parseHandler(elem, _docfind)
            _docfind = tdf
            if !isnothing(tincludes)
                if !isnothing(_docs)
                    setDocs!(tincludes, _docs)
                    _setDocs = true
                end
                if isnothing(includes)
                    includes = tincludes
                else
                    includes = vcat(includes, tincludes)
                end
            end
            if !isnothing(tuses)
                if !isnothing(_docs)
                    setDocs!(tuses, _docs)
                    _setDocs = true
                end
                if isnothing(uses)
                    uses = tuses
                else
                    uses = vcat(uses, tuses)
                end
            end
            if !isnothing(tmodules)
                if !isnothing(_docs)
                    setDocs!(tmodules, _docs)
                    _setDocs = true
                end
                if isnothing(modules)
                    modules = tmodules
                else
                    modules = vcat(modules, tmodules)
                end
            end
            if !isnothing(tfunctions)
                if !isnothing(_docs)
                    setDocs!(tfunctions, _docs)
                    _setDocs = true
                end
                if isnothing(functions)
                    functions = tfunctions
                else
                    functions = vcat(functions, tfunctions)
                end                
            end

            if _setDocs
                _docs = nothing
                _setDocs = false
            end
            
            if !isnothing(tdocs)
                _docs = tdocs
            end

        end
    elseif tmp[1] == "globalrefdoc"
        docfind = true
    elseif docfind && tmp[1] == "string"
        docfind = false
        docs = tmp[2]
    end
    tmp = nothing
    includes, uses, modules, functions, docs, docfind
end

function aux_stuff(arr)
	res = []
	for tuple in arr
		res = vcat(res, scrape_includes(tuple))
	end
	res
end

"""
auxiliary function checks wether argument expression has an args parameter that isnt empty
"""
function _checkArgs(e)
	!isnothing(e.args) && !isempty(e.args)
end



function get_links(arr::Array{Any,1})
    res = Array{Tuple{String,String},1}(undef, length(arr))
    for i in 1:length(arr)
        res[i] = get_links(arr[i])
    end
    res
end

function get_links(tuple)::Tuple{String,String}
    # get base path
    origin = split(tuple[1],"\\")[1:(end-1)]# this removes the filename
    path = split(tuple[2],"\\")
    for name in path
        if name == ".."
            if length(origin)>0
                origin = origin[1:(end-1)]# "../" means go back one folder
            else
                origin = [".."]
            end
        else
            push!(origin, name)
        end
    end
    (tuple[1],string(origin.*"/"...)[1:(end-1)])
end

function make_tree(tuple)
    lnks = get_links(tuple)
    lnks = lnks[sortperm([x[1] for x in lnks])]
    res = []
    tmp = nothing
    me = lnks[1][1]
    for link in lnks
        if link[1] == me
            # add link
            if !isnothing(tmp)
                push!(tmp, link[2])
            else
                tmp = [link[2]]
            end
        else
            # add file_node
            push!(res, file_node(me, tmp))
            # new me
            me = link[1]
            tmp = [link[2]]
        end
    end
    # do the last one
    push!(res, file_node(me, tmp))
    
    res
end
          

function firstIdentifier(e::CSTParser.EXPR)
    i = 0
    if _checkArgs(e)
        i = findfirst((x)->(x.head == :IDENTIFIER) ,e.args)
        if isnothing(i)
            throw("did not find an :IDENTIFIER in expression $e")
        end
        i
    else
        throw("tried looking for :IDENTIFIER sub expression in expression with no args: $e")
    end
    i
end


function setDocs!(elem::ModuleDef, doc)
    elem.docs = doc
end

function setDocs!(elem::FuncDef, doc)
    elem.docs = doc
end

function setDocs!(a::Array{T,1}, doc) where  {T}
    for e in a
        setDocs!(e,doc)
    end
end

function setDocs!(a::Any, doc)
    println("setDocs! is undefined for type $(typeof(a))")
end






