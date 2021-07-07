
function make_scrape_from_zip(root, zipfile)
	name = __get_name(root)	
	mkpath("tmp")
	unzip(joinpath(root, zipfile),"tmp/$(name)")
	println("parse + scrape $(name)...")
	scrape = parse_and_scrape_folder("tmp/$(name)")
	save("scrapes/$(name).jld2", Dict(name => scrape))
	println("cleanup...")
	rm("tmp/$(name)", recursive=true)
end


function make_scrapes_from_zips(dir)
	i = 0
	count = 0
	fails = []

	for (root, dirs, files) in walkdir(dir)
		for file in files
			if !isfile("scrapes/$(__get_name(root)).jld2")
				count += 1
			end
		end
	end

	for (root, dirs, files) in walkdir(dir)
		for file in files
			if !isfile("scrapes/$(__get_name(root)).jld2") && endswith(file, ".zip")
				try
					make_scrape_from_zip(root, file)					
				catch e
					println(e)
					push!(fails, (joinpath(root, file), e ))
				end
				i += 1
				println("handled zip $(i) of $(count)")		
			end	
		end
	end
	println("failed $(length(fails)) files")
	fails
end
