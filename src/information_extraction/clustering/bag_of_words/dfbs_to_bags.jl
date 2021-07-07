function dfbs_to_bags(dir)
	i = 0
	count = 0
	fails = []

	for (root, dirs, files) in walkdir(dir)
		for file in files
			if !isfile("bags/$(__get_name(root)).jld2")
				count += 1
			end
		end
	end
	stemmer=Stemmer("english")
	tokenizer=punctuation_space_tokenize
	for (root, dirs, files) in walkdir(dir)
		for file in files
			if !isfile("bags/$(__get_name(root)).jld2") && endswith(file, ".jld2")
				
				println("doing $file")
				make_bag_from_jld2(root, file, stemmer, tokenizer)					
				
				i += 1
				println("handled file $(i) of $(count)")		
			end	
		end
	end
	println("failed $(length(fails)) files")
	fails
end

function make_bag_from_jld2(root, file, stemmer=Stemmer("english"), tokenizer=punctuation_space_tokenize)
	save("bags/$file", Dict(splitext(file)[1] => file_to_bags(root, file, stemmer, tokenizer)))
end
