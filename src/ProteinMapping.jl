module ProteinMapping

include("resolve_env.jl")

using ExpressionData
using DataFrames
using RCall

function map_to_stable_ensembl_peptide(eset::ExpressionSet, attribute::String;
                                       gene_col::String="ensembl_id",
                                       mart_id::String="ensembl",
                                       mart_dataset::String="hsapiens_gene_ensembl")
    @rput eset gene_col mart_id mart_dataset attribute r_utils_path

    R"""
    suppressPackageStartupMessages({
        library(biomaRt)
        
        library(httr)
    })
    set_config(config(ssl_verifypeer = 0L))
    mart <- useMart(mart_id, dataset = mart_dataset)

    mapping <- 
    getBM(attributes = c("ensembl_peptide_id", attribute),
          filters = gene_col,
          values = unique(assayData(eset)[[gene_col]]),
          mart = mart)
    """

    mapping_r = @rget mapping
    mapping = convert(DataFrame, mapping_r)

    return esetmapping
end

end
