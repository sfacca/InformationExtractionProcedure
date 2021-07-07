
"""doc_fun_block_bag->doc_fun_block_voc"""
function out_to_scrapes(dir, verbose=false)

	for (root, dirs, files) in walkdir(dir)
		for file in files
			if file == "file.zip"
                println("handling $(splitpath(root)[end])")
				make_scrape_from_zip(root, file, verbose)
			end
		end
	end
end


function make_voc_from_jld2(root, file, verbose = true)    
	name = splitpath(root)[end]
    if verbose println("handling $name ------")
    mkpath("tmp/$name")
	if verbose println("unzipping...")
    unzip("tmp/$name/file.zip","tmp/$name")	
	if verbose println("parse/scrape...")
    parse = parse_and_scrape_folder("tmp/$name")
    if verbose println("saving...")
    save("scrapes/$(name).jld2", Dict(name => scrape))
    if verbose println("cleanup...")
	rm("tmp/$name", recursive = true)
	scrape = nothing
	parse = nothing
end