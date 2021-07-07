
"""doc_fun_block_bag->doc_fun_block_voc"""
function bags_to_dfbv(dir)
	i = 0
	count = 0
	fails = []

	for (root, dirs, files) in walkdir(dir)
		for file in files
			if !isfile("dfbv/$(__get_name(root)).jld2")
				count += 1
			end
		end
	end
	
	for (root, dirs, files) in walkdir(dir)
		for file in files
			if !isfile("dfbv/$(__get_name(root)).jld2") && endswith(file, ".jld2")
				make_voc_from_jld2(root, file)
				i += 1
				println("handled file $(i) of $(count)")		
			end	
		end
	end
	i
end


function make_voc_from_jld2(root, file)
	save("dfbv/$file", Dict(splitext(file)[1] => file_to_dfbv(root, file)))
end

function make_lexicons_from_dir(dir,  LDAC=false, save_files=true)
	i = 0
	count = 0
	x = 0

	doc_lexicon = []
	block_lexicon = []
	tmp_doc_lex = []
	tmp_block_lex = []

	for (root, dirs, files) in walkdir(dir)
		for file in files
			count += 1
		end
	end
	
	for (root, dirs, files) in walkdir(dir)
		for file in files
			# let's lower reallocation madness!
			if x >= 20
				doc_lexicon = unique(vcat(doc_lexicon, tmp_doc_lex))
				block_lexicon = unique(vcat(block_lexicon, tmp_block_lex))
				tmp_doc_lex = []
				tmp_block_lex = []
				x = 0
			end
			d, b = get_lexicons_from_file(root, file)
			tmp_doc_lex = unique(vcat(tmp_doc_lex, d))
			tmp_block_lex = unique(vcat(tmp_block_lex, b))
			x +=1
			i += 1
			println("handled file $(i) of $(count)")	
		end
	end
	doc_lexicon = unique(vcat(doc_lexicon, tmp_doc_lex))
	block_lexicon = unique(vcat(block_lexicon, tmp_block_lex))
	if save_files
		#write_lexicons(doc_lexicon, block_lexicon)
		save("doc_lexicon.jld2", Dict("doc_lexicon"=>doc_lexicon))
		save("block_lexicon.jld2", Dict("block_lexicon"=>block_lexicon))
		if LDAC
			write_lexicon(doc_lexicon, "doc_vocab.lexicon")
			write_lexicon(block_lexicon, "block_lexicon.lexicon")		
		end
	end
	doc_lexicon, block_lexicon
end
