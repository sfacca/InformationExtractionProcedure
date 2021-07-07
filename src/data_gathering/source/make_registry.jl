struct ModDef
	version::String
	url::String
	name::String
	ModDef() = new("","","")
	ModDef(a::String, b::String, c::String) = new(a,b,c)
end

function Toml_to_ModDef(path::String)
	pkgtoml = read(path, String)
	items = split(pkgtoml, "\n")
	i = 1
	f = false
	name = nothing
	url = nothing
	version = nothing
	for part in items
		if occursin(r"repo =", part)
			url = replace(
				string(
					split(part, "\"")[2]
					,
					"12 34"),
				r".git12 34"=>"/archive/master.zip"
			)
		elseif occursin(r"uuid = ", part)
			version = split(part, "\"")[2]
		elseif occursin(r"name = ", part)
			name = split(part, "\"")[2]
		end
	end
	
	if isnothing(name) || isnothing(url) || isnothing(version)
		ModDef()
	else
		ModDef(string(version), string(url), string(name))
	end		
end

function get_ModDefs(dir)
	res = Array{ModDef,1}(undef,0)
	i = 1
	for (root, dirs, files) in walkdir(dir)	
        for file in files
            if endswith(file, ".toml")
              	push!(res, Toml_to_ModDef(joinpath(root, file)))
            end
			println("######## FILE $i DONE ########")
			i+=1
        end
    end
	unique(res)
end

function mds_to_dict(arr::Array{ModDef,1})
	dict = Dict()
	for md in arr
		if md.name == "" || md.url == ""
		else
			push!(dict, md.name => md.url)
		end
	end
	dict
end

function make_registry(target="registry")
	dir="tmp"
	mkpath(dir)
	println("downloading registry...")
	download("https://github.com/JuliaRegistries/General/archive/master.zip","$dir/master.zip")

	println("unzipping...")
	unzip("$dir/master.zip")

	println("scraping module definitions...")
	mds = unique(get_ModDefs("$dir/General-master"))

	println("making dictionary...")
	modules_dict = mds_to_dict(mds)

	println("removing temporary folder...")
	rm(dir, recursive=true)
	
	println("saving...")
	save( "$target.jld2", Dict("registry"=>modules_dict))
end