function split_array(arr, L)
    K = length(arr)
    
    if K < L
        return [arr]
    end
    
    n = div(K - 1, L) + 1
    r = mod(K, L)
    
    result = Vector{Vector{eltype(arr)}}()
    
    start_idx = 1
    for i in 1:n-1
        push!(result, view(arr, start_idx:start_idx+L-1))
        start_idx += L
    end
    
    if r > 0
        push!(result, view(arr, start_idx:start_idx+r-1))
    end
    
    return result
end
