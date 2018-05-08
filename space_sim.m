function [s, k, k1, k2] = space_sim(L,M)

    k1 = rank(L);
    k2 = rank(M);
    k = min(k1,k2);
    
    S = L*(M.')*M*(L.');
    
    s = trace(S)/k;
end