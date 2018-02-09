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

%% initialize variables
nfibers = size(fibers,1);
nvertices = size(vertices,1);
if varargin < 3
  opts = struct();
elseif iscell(opts)
  opts = struct(opts{:});
elseif ~isstruct(opts)
  error('unknown format for opts\n');
end % if varargin < 3

% set default options
if ~isfield(opts,'weighted'), opts.weighted = FALSE; end

%% generate adjacency matrix
cmat = zeros(nvertices);

for f=1:nfibers
  fstart = repmat(fibers{f}(:,1)',nvertices,1);
  fend   = repmat(fibers{f}(:,end)',nvertices,1);
  mstart = find(sum(abs(vertices - fstart),2) == min(sum(abs(vertices - fstart),2)));
  mend   = find(sum(abs(vertices - fend),2)   == min(sum(abs(vertices - fend),2)));
  
  if opts.weighted
    cmat(mstart,mend) = cmat(mstart,mend)+1;
  else
    cmat(mstart,mend) = 1;
  end % if opts.weighted
end % for ff=1:nfibers

