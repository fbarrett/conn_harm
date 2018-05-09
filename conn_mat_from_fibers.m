function A = conn_mat_from_fibers(fibers,vertices,opts)

% map fiber start and end to grey matter vertices
% 
%   A = conn_mat_from_fibers(fibers,vertices,opts)
% 
% INPUT
%   fibers - cell array of Mx3 matrices of fiber tracts, with coordinates
%       for M fibers in each cell
%   vertices - Nx3 matrix of coordinates for N vertices
%   opts - structure containing optional settings
%       .weighted (FALSE) - if true, each cell in A will reflect the
%       number of fibers connecting a given pair of vertices. If false,
%       each cell in A will reflect presence or absence of connecting
%       fibers.
% 
% OUTPUT
%   A - NxN adjacency matrix based on fibers
% 
% fbarrett@jhmi.edu 2018.02.09

%% initialize variables
tic
nfibers = size(fibers,1);
nvertices = size(vertices,1);
if nargin < 3
  opts = struct();
elseif iscell(opts)
  opts = struct(opts{:});
elseif ~isstruct(opts)
  error('unknown format for opts\n');
end % if varargin < 3

% set default options
if ~isfield(opts,'weighted'), opts.weighted = false; end

%% generate adjacency matrix
A = zeros(nvertices);

fprintf(1,'conn_mat_from_fibers.m - generating connectivity matrix\n');
for f=1:nfibers
  if ~mod(f,round(nfibers/10)), fprintf(1,'%d%%..',round(f/nfibers*100)); end
  
  fstart = repmat(fibers{f}(:,1)',nvertices,1);
  fend   = repmat(fibers{f}(:,end)',nvertices,1);
  mstart = find(sum(abs(vertices - fstart),2) == min(sum(abs(vertices - fstart),2)));
  mend   = find(sum(abs(vertices - fend),2)   == min(sum(abs(vertices - fend),2)));
  
  if opts.weighted
    A(mstart,mend) = A(mstart,mend)+1;
  else
    A(mstart,mend) = 1;
  end % if opts.weighted
end % for ff=1:nfibers
fprintf(1,'\nconn_mat_from_fibers.m - done in %0.2f s.\n',toc);

