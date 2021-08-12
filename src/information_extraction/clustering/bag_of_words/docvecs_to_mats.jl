
"""doc_fun_block_docvecs => documents matrix"""
function make_matrix_from_dir(dir, save_files=false)
	#1 load every doc_fun_block_docvecs array in dir
	doc_docvecs = []
	block_docvecs = []
	fun_names = []
	source_ranges = []
	i=0
	println("loading docvecs...")
	for (root, dirs, files) in walkdir(dir)
		for file in files
			if endswith(file, ".jld2")
				tmp = FileIO.load(joinpath(root, file))[splitext(file)[1]]#this is an array of doc_fun_block_docvecs
				


				if length(tmp)>0
					start = length(doc_docvecs)+1
					doc_docvecs = vcat(doc_docvecs, [x.doc for x in tmp])
					fun_names = vcat(fun_names, [x.fun for x in tmp])
					block_docvecs = vcat(block_docvecs, [x.block for x in tmp])	
					
					range = start:(length(fun_names))
				else
					range= 0:0
				end


				push!(source_ranges, (splitext(file)[1], range))
				i += 1
				println("loaded file $(i)")
			end	
		end
	end

	# changing the way the block/doc vecs are taken + reshape might be much faster...

	println("building doc mat...")
	# one column is a docvec
	doc_mat = spzeros(length(doc_docvecs[1]),length(doc_docvecs))#row, cols
	for i in 1:length(doc_docvecs)
		doc_mat[:,i] = doc_docvecs[i]
		if i/100 == round(i/100)
			println("built document vector column $i out of $(length(doc_docvecs)) for doc matrix")
		end
	end
	println("building block mat...")
	block_mat = spzeros(length(block_docvecs[1]),length(block_docvecs))#row, cols
	for i in 1:length(block_docvecs)
		block_mat[:,i] = block_docvecs[i]
		if i/100 == round(i/100)
			println("built document vector column $i out of $(length(block_docvecs)) for block matrix")
		end
	end

	println("returning doc_mat, block_mat, fun_names, source_ranges...")
	if save_files
		println("saving files block.documents and doc.documents")
		IEP.write_documents(block_mat,"block_bags.documents")
		IEP.write_documents(doc_mat,"doc_bags.documents")
		
	end
	Int32.(doc_mat), Int32.(block_mat), fun_names, source_ranges
end


function make_indexing(fun_names, src_ranges)
	indexes = Array{NamedTuple{(:source, :fun),Tuple{String, String}},1}(undef,length(fun_names))

	for tuple in src_ranges
		name = tuple[1]
		range = tuple[2]
		if range != 0:0
			for i in range
				indexes[i] = (source = name, fun = fun_names[i])
			end
		end
	end
	indexes
end
