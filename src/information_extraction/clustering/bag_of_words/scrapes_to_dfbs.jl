function scrapes_to_dfbs(dir)
	i = 0
	count = 0
	fails = []

	for (root, dirs, files) in walkdir(dir)
		for file in files
			if !isfile("dfbs/$(__get_name(root)).jld2")
				count += 1
			end
		end
	end

	for (root, dirs, files) in walkdir(dir)
		for file in files
			if !isfile("dfbs/$(__get_name(root)).jld2") && endswith(file, ".jld2")
				try
					make_dfb_from_jld2(root, file)					
				catch e
					println(e)
					push!(fails, (joinpath(root, file), e ))
				end
				i += 1
				println("handled file $(i) of $(count)")		
			end	
		end
	end
	println("failed $(length(fails)) files")
	fails
end

function make_dfb_from_jld2(root, file)
	save("dfbs/$file", Dict(splitext(file)[1] => file_to_doc_fun_block(root, file)))
end

function __get_name(root)
	split(root, "\\")[end]
end