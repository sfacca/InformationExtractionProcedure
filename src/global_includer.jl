function make_global_includer(dir)
	includes = []

	for (root, dirs, files) in walkdir(dir)
		for file in files
			if endswith(file, "jl")
				push!(includes, joinpath(root,file))
			end
		end
	end
	
	write_global_includer(dir, includes)
end


function write_global_includer(dir, includes)
    
    open("$dir.jl", "w") do io
        for inc in includes
            write(io, replace("""include("$inc")\n""", "\\"=>"/"))
        end
    end
end

"make_global_includer(dir)"