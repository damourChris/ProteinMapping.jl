module ProteinMapping

include("resolve_env.jl")

using DataFrames
using RCall
import Base.Threads.@spawn

include(joinpath("utils.jl"))

const mart_id = "ensembl"
const mart_dataset = "hsapiens_gene_ensembl"

export map_to_stable_ensembl_peptide

function map_to_stable_ensembl_peptide(ids_to_map::Vector{String},
                                       attribute::String)

    # Check how long ids_to_map is, and if it's bigger than 50 we should batch the queries
    if length(ids_to_map) > 50
        return map_to_stable_ensembl_peptide_batched(ids_to_map, attribute)
    end

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

function map_to_stable_ensembl_peptide_batched(ids_to_map::Vector{String},
                                               attribute::String)
    @info "Batching the query"
    # Split the ids_to_map into chunks of 50
    chunks = split_array(ids_to_map, 50)

    # Create a channel to collect results
    result_channel = Channel(length(chunks))

    # Initialize an empty DataFrame to store the results
    mapping = DataFrame()

    # Function to process a chunk
    function process_chunk(chunk)
        mapping_chunk = map_to_stable_ensembl_peptide(chunk, attribute)
        return put!(result_channel, mapping_chunk)
    end

    # Submit tasks to the thread pool
    threads = []
    for chunk in chunks
        push!(threads, @spawn process_chunk(chunk))
    end

    # Collect results
    mapping_chunks = Vector{DataFrame}(undef, length(chunks))
    for i in 1:length(chunks)
        mapping_chunks[i] = take!(result_channel)
    end

    # Combine results
    mapping = reduce(vcat, mapping_chunks)

    return mapping
end


end
