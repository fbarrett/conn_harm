% 
%
% 

% analyzed from ltmewd_bold_decomp_connharm
ranges = {1:20,21:40,41:60,61:80,81:100};
energy = [];
totnrgy = [];
entr = [];
nvertex = 20484;

for k=[3 5 8 10]
  tic
  this = load(analyzed{3});
  Asparse = load(this.paths.adj_path);  % load sparse adjacency matrix
  A = zeros(nvertex);
  for k=1:size(Asparse,1) % populate a full matrix
    A(Asparse(k,1),Asparse(k,2)) = Asparse(k,3);
    A(Asparse(k,2),Asparse(k,1)) = Asparse(k,3);
  end % for k=1:size(Asparse,1
  A(find(eye(size(A,1)))) = 0; % remove the diagonal
  clear Asparse;

  % calculate symmetric graph Laplacian
  D = diag(sum(A));
  L = D - A;
  clear A;
  Dp = mpower(D,-0.5);
  clear D;
  G = Dp*L*Dp;
  clear L Dp;
  E = eig(G);
  clear G;  
  toc
  
  for r=ranges
    
  end % forr=ranges
end % fork=[]