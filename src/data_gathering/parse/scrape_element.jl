
"""
checks if argument expression defines a function
if so, returns the FuncDef
otherwise, returns nothing
"""
function scrapeFuncDef(e::CSTParser.EXPR)::Union{FuncDef, Nothing}
	# 1 returns FuncDef if e defines function, Nothing if it doesnt
	if isAssignmentOP(e)
		# an assignment operation can be a function definition 
		# if rvalue is a nameless function, defined with an -> operation
		if isArrowOP(e.args[2])
			# e.args contains the lvalue and rvalue of the -> operation
			# we also now know that the lvalue of the assignment operation 
			# is the function name
			#println("funcdef?")
			return FuncDef(
				scrapeName(e.args[1]),
				scrapeInputs(e.args[2].args[1]),
				e
			)
		elseif e.args[1].head == :call
			# we're in the name(vars) = block pattern
			# we can run scrapeinputs on the :call, 
			# the first input will actually be the function name			
			tmp = scrapeInputs(e.args[1])
			inputs = length(tmp) > 1 ? tmp[2:end] : Array{InputDef,1}(undef, 0)
			# the function code will be the rvalue of the assignment operation e
			return FuncDef(
				scrapeName(e.args[1].args[1]),
				inputs,
				e				
			)
		end
	elseif e.head == :function
		# this is the basic function name(args) block pattern
		# args[1] could be the call or an :: OP
		if e.args[1].head == :call
			# we're in the name(vars) = block pattern
			# we can run scrapeinputs on the :call, 
			# the first input will actually be the function name			
			tmp = scrapeInputs(e.args[1])
			inputs = length(tmp) > 1 ? tmp[2:end] : Array{InputDef,1}(undef, 0)
			# the function code will be the rvalue of the assignment operation e
			return FuncDef(
				scrapeName(e.args[1].args[1]),
				inputs,
				e# the whole function				
			)
		elseif isTypedefOP(e.args[1])
			# this function defines its output type
			if _checkArgs(e.args[1])&&_checkArgs(e.args[1].args[1])&&e.args[1].args[1].head == :call
				# we're in the name(vars) = block pattern
				# we can run scrapeinputs on the :call, 
				# the first input will actually be the function name			
				tmp = scrapeInputs(e.args[1].args[1])
				inputs = length(tmp) > 1 ? tmp[2:end] : Array{InputDef,1}(undef, 0)
				
				# the function code will be the rvalue of the assignment operation e
				return FuncDef(
					scrapeName(e.args[1].args[1].args[1]),
					inputs,
					e,
					scrapeName(e.args[1].args[2])
				)
			else
				return FuncDef(
					":function's typedef operator didnt have a :call as its leftvalue",
					e					
				)
			end
		end	
	else
		return nothing
	end
	nothing
end	

"""
takes an expr that defines a function adress/name, returns NameDef
"""
function scrapeName(e::CSTParser.EXPR)::NameDef
	#println("scrapename")
	NameDef(e)
end

"""
takes an expr that defines inputs, returns array of InputDef
the expr needs to only contain argument definitions in its .args array
:function -> :call function definitions have their function name in the same args
"""
function scrapeInputs(e::CSTParser.EXPR)::Array{InputDef,1}
	#println("scrape inputs")
	if _checkArgs(e)
		arr = Array{InputDef,1}(undef, length(e.args))
		for i in 1:length(arr)
			# is this a simple param name or is this a :: OP?
			if isTypedefOP(e.args[i])
				#println("TYPEDEFOP")
				try
					if length(e.args[i].args)<2
						#println("args < 2")
						#this is a weird ::Type curly thing probably
						arr[i] = InputDef(
							scrapeName(e.args[i].args[1]),
							scrapeName(e.args[i].args[1])
						)
					else
						#println("args > 2")
						arr[i] = InputDef(
						scrapeName(e.args[i].args[1]),
						scrapeName(e.args[i].args[2])
					)
					end
				catch err
					#println("error!")
					println(err)
					#println(e.args)
				end
			else
				arr[i] = InputDef(
					scrapeName(e.args[i]), 
					scrapeName(CSTParser.parse("x::Any").args[2])
				)
			end
		end		
	else
		arr = Array{InputDef,1}(undef, 0)
	end
	#println("finished scraping inputs")
	arr
end



function scrapeModuleDef(e::CSTParser.EXPR)
    res = nothing
    if e.head == :module
        res = ModuleDef(e)
        if _checkArgs(e)
            if _checkArgs(e.args[3])
                includes, usings, submodules, implements = _handleExprArr(e.args[3].args)
                res.includes, res.usings, res.submodules, res.implements = includes, usings, submodules, implements
            end
        end
    end
    res
end


function _genericScrape(expr::CSTParser.EXPR)
    res = is_include(expr)    
    if !isnothing(res)
        res = ("include", res)
    else
        res = is_using(expr)
        if !isnothing(res)
            res = ("using", res)
        else
            res = scrapeModuleDef(expr)
            if !isnothing(res)                
               res = ("module", res)
            else
                res = scrapeFuncDef(expr)
                if !isnothing(res)
                    res = ("function", res)
                else
                    if expr.head == :macrocall 
                        # macrocall can have docstrings
                        tmp = []
                        if _checkArgs(expr)
                            for arg in expr.args
                                push!(tmp, _genericScrape(arg))
                            end
                        end
                        res = ("macrocall", tmp)
                    elseif expr.head == :globalrefdoc
                        res = ("globalrefdoc", "")
                    elseif expr.head == :TRIPLESTRING
                        res = ("string", expr.val)
                    end
                end
            end
        end
    end
    res
end



function scrape_includes(e::CSTParser.EXPR)::Array{String}
	res = Array{String,1}(undef, 0)
	tmp = is_include(e)
	if !isnothing(tmp)
		res = [tmp]
	else
        if _checkArgs(e)
            for sube in e.args
                res = vcat(res, scrape_includes(sube))
            end
        end
	end
    #println(typeof(res))
	res
end


function scrape_includes(arr::Array{CSTParser.EXPR,1})::Array{String}
	res = Array{String,1}(undef, 0)
	for e in arr
        res = vcat(res,scrape_includes(e))
	end
	res
end


function scrape_includes(tuple::Tuple{CSTParser.EXPR,String})
	[(tuple[2], x) for x in scrape_includes(tuple[1])]
end


function scrape_usings(e::CSTParser.EXPR)
    res = getUsings(e)
    if length(res) == 0
        # e wasnt a using expression
        # we look at the sub expressions
        if _checkArgs(e)
            for arg in e.args
                res = vcat(res, scrape_usings(arg))
            end
        end
    end
    res    
end

function scrapeModules(e::CSTParser.EXPR)
    res = Array{ModuleDef,1}(undef,0)
    tmp = is_moduledef(e)
    if !isnothing(tmp)
        res= [ModuleDef(e)]
    end
    # finding submodules
    if _checkArgs(e)
        for arg in e.args
            res = vcat(res, scrapeModules(arg))
        end
    end
    res
end


  