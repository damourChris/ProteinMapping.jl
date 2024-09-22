module ProteinMapping

include("resolve_env.jl")

using DataFrames
using RCall

const mart_id = "ensembl"
const mart_dataset = "hsapiens_gene_ensembl"

export map_to_stable_ensembl_peptide

function map_to_stable_ensembl_peptide(ids_to_map::Vector{String},
                                       attribute::String)
    @rput ids_to_map attribute mart_id mart_dataset

    R"""
    suppressPackageStartupMessages({
        library(biomaRt)
        library(httr)
    })
    set_config(config(ssl_verifypeer = 0L))
    mart <- useMart(mart_id, dataset = mart_dataset)

    mapping <- getBM(attributes = c(attribute, "ensembl_peptide_id"),
          filters = attribute,
          values = ids_to_map,
          mart = mart)          
    """

    mapping_r = @rget mapping
    mapping = convert(DataFrame, mapping_r)

    return mapping
end

end
