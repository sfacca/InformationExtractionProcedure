function dfbvs_to_docvecs(dir, doc_lexicon=FileIO.load("doc_lexicon.jld2")["doc_lexicon"], block_lexicon=FileIO.load("block_lexicon.jld2")["block_lexicon"])
	i = 0
	count = 0


	get_lexicons
	for (root, dirs, files) in walkdir(dir)
		for file in files
			if endswith(file, ".jld2")
				count += 1
			end
		end
	end

	doc_dict = dict_of_lexicon(doc_lexicon)
	block_dict = dict_of_lexicon(block_lexicon)
	
	for (root, dirs, files) in walkdir(dir)
		for file in files
			if endswith(file, ".jld2")

				save_docvecs_from_file(root, file, doc_dict, block_dict)
								
				i += 1
				println("handled file $(i) of $(count)")
			end	
		end
	end
	i
end

function dir_to_lexicons(dir)
	
	for (root, dirs, files) in walkdir(dir)
		for file in files
			if endswith(file, ".jld2")
				count += 1
			end
		end
	end

	tmp = Array{doc_fun_block_voc,1}(undef, count)
	i = 0
	for (root, dirs, files) in walkdir(dir)
		for file in files
			if endswith(file, ".jld2")
				i += 1
				tmp[i] = load(joinpath(root, file))[splitext(file)[1]]						
				println("loaded file $(i) of $(count)")
			end	
		end
	end

	doc_lexi, block_lexi = get_lexicons(tmp)
	tmp = nothing
	save("doc_lexicon.jld2", Dict("doc_lexicon"=>doc_lexi))
	save("block_lexicon.jld2", Dict("block_lexicon"=>block_lexi))
end

function save_docvecs_from_file(root, file, doc_dict, block_dict)
	save("dfbdocvecs/$file", Dict(splitext(file)[1] => file_to_docvecs(root, file, doc_dict, block_dict)))
end