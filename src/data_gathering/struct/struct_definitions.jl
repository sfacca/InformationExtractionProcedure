struct NameDef
	name::CSTParser.EXPR
	padding::Nothing
	NameDef(n) = new(n, nothing)
end

struct InputDef
	name::NameDef
	type::NameDef
	
end

mutable struct FuncDef
	name::Union{NameDef, Int32}
	inputs::Array{InputDef,1}
	block::CSTParser.EXPR
	output::Union{Nothing,NameDef}
	docs::Union{String,Nothing}
	source::Union{String,Nothing}
	FuncDef(n::NameDef,i::Array{InputDef,1},b::CSTParser.EXPR,o::NameDef) = new(n,i,b,o,nothing,nothing)
	FuncDef(n::NameDef,i::Array{InputDef,1},b::CSTParser.EXPR) = new(n,i,b,nothing,nothing,nothing)
	FuncDef(error::String, block::CSTParser.EXPR) = new(
		NameDef(error,"FUNCDEF_ERROR"),
		Array{InputDef,1}(undef, 0),
		block,
		nothing,
		nothing,
		nothing
	)
	FuncDef(
		a::NameDef,
		b::Array{InputDef,1},
		c::CSTParser.EXPR,
		d::Union{Nothing,NameDef}=nothing,
		e::Union{String,Nothing}=nothing,
		f::Union{String,Nothing}=nothing
		)=new(a,b,c,d,e,f)

end

mutable struct ModuleDef
    name::String
    submodules::Union{Array{ModuleDef,1},Nothing}
    usings::Union{Array{String,1},Nothing}
    includes::Union{Array{String,1},Nothing}
    implements::Union{Array{FuncDef, 1}, Nothing}
    docs::Union{String, Nothing}
    ModuleDef(a,b,c,d,e,f) = new(a,b,c,d,e,f)    
    ModuleDef(a,b,c,d,e::Array{FuncDef, 1},f) = new(a,b,c,d,_conv(e),f)
    ModuleDef(name::String, doc::String) = new(name, [], [], [], [], doc)    
    ModuleDef(e::CSTParser.EXPR, doc::String) = ModuleDef(e.args[firstIdentifier(e)].val, doc)
    ModuleDef(name::String) = new(name, [], [], [], [], nothing)
    ModuleDef(e::CSTParser.EXPR) = ModuleDef(e.args[firstIdentifier(e)].val)    
end

mutable struct FileDef
    path::String
    uses
    modules
    functions
    includes
    FileDef(a,b,c,d,e) = new(a,b,c,d,e)
    FileDef() = new("empty", [],[], [], [])
end

function FunctionContainer(f::FuncDef, docs=nothing, source=nothing)
	FuncDef(f.name,f.inputs,f.block,f.output)
end