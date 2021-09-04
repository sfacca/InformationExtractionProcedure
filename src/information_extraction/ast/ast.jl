


mutable struct expr_node
    id::Int
    type::Symbol
    value::Union{String,Nothing}
    children::Array{Union{Int,expr_node},1}
end

#=
mutable struct expr_dict
    types::Array{String,1}
    nodes::Array{}
end=#

mutable struct expr_lexi
    lexi::Array{expr_node,1}
    last::Int
end

function same_node(a::expr_node, b::expr_node)::Bool
    a.value == b.value && a.type == b.type && a.children == b.children
end

function same_value(a::expr_node, b::expr_node)::Bool
    a.value == b.value
end

function get_ast(expr::CSTParser.EXPR)::expr_node

    id = 0
    if typeof(expr.head) == CSTParser.EXPR
        type = expr.head.head
        value = expr.head.val
    else
        type = expr.head
        value = expr.val
    end

    if !isnothing(expr.args) && !isempty(expr.args)
        children = [get_ast(a) for a in expr.args]
    else
        children = []
    end

    expr_node(id, type, value, children)
end

function ast_size(root::expr_node)::Int
    if isempty(root.children)
        1
    else
        res = 1
        for child in root.children
            res += ast_size(child)
        end
        res
    end
end

function init_lexi(starting_size::Int)::expr_lexi
    expr_lexi(Array{expr_node,1}(undef, starting_size), 0)
end

function flatten_ast!(arr::Array{Any,1})
    nodes = 0
    for node in arr
        nodes += ast_size(node)
    end
    lexi = init_lexi(nodes)
    for node in arr
        flatten_ast!(node, lexi)
    end
    lexi
end



function flatten_ast!(root::expr_node, lexicon::expr_lexi = init_lexi(ast_size(root)))::Int
    if isempty(expr_node.children)
        if isempty(lexicon)
            root.id = 1
            add_to_lexi!(lexicon, root)      
        else
            e_id = findfirst((x)->(same_node(x, root)), lexicon)
            if isnothing(e_id)
                root.id = length(lexicon) + 1
                add_to_lexi!(lexicon, root) 
            else
                root.id = e_id
            end
        end 
            
    else
        root.children = [flatten_ast!(child, lexicon) for child in root.children]
        if isempty(lexicon)
            root.id = 1
            add_to_lexi!(lexicon, root)            
        else
            e_id = findfirst((x)->(same_node(x, root)), lexicon)
            if isnothing(e_id)
                root.id = length(lexicon) + 1
                add_to_lexi!(lexicon, root) 
            else
                root.id = e_id
            end
        end
    end
    root.id
end

function add_to_lexi!(lexi::expr_lexi, node::expr_node)
    lexi.last += 1
    if length(lexi.lexi) < lexi.last
        tmp = Array{expr_node, 1}(undef, lexi.last * 2)
        tmp[1:(length(lexi.lexi))] = lexi.lexi
        lexi.lexi = tmp
    end
    lexi.lexi[lexi.last] = node
end



function dfb_to_ast(dir)
    i = 0
    count = 0
    fails = []
    
    for (root, dirs, files) in walkdir(dir)
        for file in files
            count += 1
        end
    end

    for (root, dirs, files) in walkdir(dir)
        for file in files
            make_ast_from_jld2(root, file)
            i += 1
            println("handled file $(i) of $(count)")	
        end
    end
end
    
function make_ast_from_jld2(root, file)
    save("ast/$file", Dict(splitext(file)[1] => file_to_ast(root, file)))
end

function file_to_ast(root, file)
    dfbs = FileIO.load(joinpath(root, file))[splitext(file)[1]]
    [(x.fun, get_ast(x.block)) for x in dfbs]
end

function __get_name(root)
    split(root, "\\")[end]
end

function files_to_ast(dir)
    i = 0
    count = 0
    fails = []
    
    for (root, dirs, files) in walkdir(dir)
        for file in files
            count += 1
        end
    end
    names = []
    res = []
    for (root, dirs, files) in walkdir(dir)
        for file in files
            tmp = FileIO.load(joinpath(root, file))[splitext(file)[1]]
            println("loaded file $i of $count")
            names = vcat(names, [x.fun for x in tmp])
            res = vcat(res, [get_ast(x.block) for x in tmp])
            i+=1
        end
    end

    names, res
end