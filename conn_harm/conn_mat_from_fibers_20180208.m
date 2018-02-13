function cmat = conn_mat_from_fibers(fibers,vertices,opts)

% map fiber start and end to grey matter vertices
% 
%   cmat = conn_mat_from_fibers(fibers,vertices,opts)
% 
% INPUT
%   fibers - cell array of Mx3 matrices of fiber tracts, with coordinates
%       for M fibers in each cell
%   vertices - Nx3 matrix of coordinates for N vertices
%   opts - structure containing optional settings
%       .weighted (FALSE) - if true, each cell in cmat will reflect the
%       number of fibers connecting a given pair of vertices. If false,
%       each cell in cmat will reflect presence or absence of connecting
%       fibers.
% 
% OUTPUT
%   cmat - NxN adjacency matrix based on fibers
% 
% fbarrett@jhmi.edu 2018.02.09

nfibers = size(fibers,1);
nvertices = size(vertices,1);

midxs = nan(nfibers,2);
for ff=1:nfibers
  fstart = repmat(fibers{ff}(:,1)',nvertices,1);
  fend   = repmat(fibers{ff}(:,end)',nvertices,1);
  mstart = find(sum(abs(vertices - fstart),2) == min(sum(abs(vertices - fstart),2)));
  mend   = find(sum(abs(vertices - fend),2)   == min(sum(abs(vertices - fend),2)));
  midxs(ff,:) = [mstart mend];
end % for ff=1:nfibers

