function is_using(e::CSTParser.EXPR)
    res = nothing
    if e.head == :using
        if _checkArgs(e)
            # some modules might be dotted (eg TextAnalysis.Parse)
            # we just get the base one
            res = unique([string(x.args[1].val) for x in e.args])# unique because ^            
            # we might get "nothing"
            res = filter((x)->(x != "nothing"), res)
        end
    end
    res
end

"""
this function returns included file if the given expr is an include, nothing otherwise"""
function is_include(e::CSTParser.EXPR)::Union{Nothing, String}
    res = nothing
    if e.head == :call
        # it's a call, let's check called function
        if !isnothing(e.args) && length(e.args)>1
            if e.args[1].head == :IDENTIFIER && e.args[1].val == "include"
                res = e.args[2].val
            end
        end
    end
    res
end


"""
this function returns included file if the given expr is an include, nothing otherwise"""
function is_include(e::CSTParser.EXPR)::Union{Nothing, String}
    res = nothing
    if e.head == :call
        # it's a call, let's check called function
        if !isnothing(e.args) && length(e.args)>1
            if e.args[1].head == :IDENTIFIER && e.args[1].val == "include"
                res = e.args[2].val
            end
        end
    end
    res
end


"""
this function returns included file if the given expr is an include, nothing otherwise"""
function is_include(e::CSTParser.EXPR)::Union{Nothing, String}
    res = nothing
    if e.head == :call
        # it's a call, let's check called function
        if !isnothing(e.args) && length(e.args)>1
            if e.args[1].head == :IDENTIFIER && e.args[1].val == "include"
                res = e.args[2].val
            end
        end
    end
    res
end

"""returns nothing if expression isnt a module def, expression of module otherwise"""
function is_moduledef(e::CSTParser.EXPR)
    (e.head == :module) ? e : nothing
end


function is_using(e::CSTParser.EXPR)
    res = nothing
    if e.head == :using
        if _checkArgs(e)
        else
            # some modules might be dotted (eg TextAnalysis.Parse)
            # we just get the base one
            res = unique([string(x.args[1].val) for x in e.args])# unique because ^            
            # we might get "nothing"
            res = filter((x)->(x != "nothing"), res)
        end
    end
    res
end

"""
uses isOP to check if argument expression is a OP: =
"""
function isAssignmentOP(e::CSTParser.EXPR)
	isOP(e,"=")
end

"""
uses isOP to check if argument expression is a OP: ->
"""
function isArrowOP(e::CSTParser.EXPR)
	isOP(e,"->")
end

"""
uses isOP to check if argument expression is a OP: ::
"""
function isTypedefOP(e::CSTParser.EXPR)
	isOP(e,"::")
end

"""
uses isOP to check if argument expression is a OP: .
"""
function isDotOP(e::CSTParser.EXPR)
	isOP(e,".")
end

"""
after sanity checks, checks wether argument expression is operator op
"""
function isOP(e::CSTParser.EXPR, op::String)
	if !isnothing(e.head) && typeof(e.head) == CSTParser.EXPR
		if !isnothing(e.head.head) && e.head.head == :OPERATOR && e.head.val == op
			true
		else
			false
		end
	else
		false
	end
end

#=
    contains get-type functions that return iunformation on the input CSTParser.EXPR
=#

"""
uses isOP to check if argument expression is a OP: .
"""
function isDotOP(e::CSTParser.EXPR)
	isOP(e,".")
end

"""
after sanity checks, checks wether argument expression is operator op
"""
function isOP(e::CSTParser.EXPR, op::String)
	if !isnothing(e.head) && typeof(e.head) == CSTParser.EXPR
		if !isnothing(e.head.head) && e.head.head == :OPERATOR && e.head.val == op
			true
		else
			false
		end
	else
		false
	end
end

"""
returns true if input expression is an Op
"""
function isOP(e::CSTParser.EXPR)
	if !isnothing(e.head) && typeof(e.head) == CSTParser.EXPR
		if !isnothing(e.head.head) && e.head.head == :OPERATOR
			true
		else
			false
		end
	else
		false
	end
end

