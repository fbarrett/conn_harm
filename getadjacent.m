function [adjacents, passed] = getadjacent(vertex, dist, hashtab)

% extract adjacents within distance from vertex, from a hash table
% 
%   [adjacents,passed] = getadjacent(vertex, dist, hashtab)
% 
% INPUTS
%   vertex - string indicating vertex number for which you want to find
%       adjacents
%   dist - distance (in vertices) from the vertex within which to find and
%       return adjacents
%   hashtab - hash table of all adjacent vertices
% 
% OUTPUTS
%   adjacents - neighboring vertices to "vertex" within "dist"
%   passed - vertex
% 
% EXAMPLE
%   getadjacent(?4756?, 1, ?myfile.surf?) you get out:
%       adjacents =  the 6 neighbouring vertices to the central vertex
%       passed = the value of the central vertex itself
% 
% FROM:
% https://mail.nmr.mgh.harvard.edu/pipermail//mne_analysis/2013-May/001529.html
% by Li Su and Andy Thwaites

adjacentsbelow = [];
adjacents = [];
passed = [];
if dist==1
   adjacents = hashtab.get(vertex);
   passed = [1];
else
   [adjacentsbelow passed] = getadjacent(vertex, dist-1, hashtab);
   for j = 1:length(adjacentsbelow)
      adjacents = [adjacents; hashtab.get(num2str(adjacentsbelow(j)))];
   end
   adjacents = unique(adjacents);
   passed = [passed; adjacentsbelow];
   for j = length(adjacents):-1:1
      if(any(find(passed == adjacents(j))))
          adjacents(j)=[];
      end
   end
end

adjacents = unique(adjacents);
passed = unique(passed);