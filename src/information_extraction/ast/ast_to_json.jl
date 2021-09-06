function ast_to_json(arr::Array{IEP.expr_node,1})
    res = []

    for ast in arr
        push!(res, ast_to_json(ast))
    end
    res
end

function ast_to_json(arr::Array{Array{IEP.expr_node,1},1})
    res = []

    for aast in arr
        push!(res, [ast_to_json(x) for x in aast])
    end
    res
end

function ast_to_json(x::IEP.expr_node)
    """{"id": $(x.id), "type": $(x.type), "value": $(x.value), "children": $(x.children)}"""
end

function save_json(arr, name)

    open(name, "w") do io
        for line in arr
            write(io, "\n[")
            write(io, join(line, ", "))            
            write(io, "]")
        end
    end
end