% make local neighborhood connectivity matrix for a given surface
% 
% based on code to generate a hashtable containing all the adjacent
% vertices from a specified surf file
% 
% FROM:
% https://mail.nmr.mgh.harvard.edu/pipermail//mne_analysis/2013-May/001529.html
% Written by Andy Thwaites. Modified by Su Li. 2012
% adapted by fbarrett@jhmi.edu 2018.04.07

radius = 1;                % distance from center to consider connectivity
h = {'l','r'};
fspath = '/Applications/freesurfer';
fspath = '/g5/fbarret2/fs-subjects';
basesub = 'fsaverage4';
surfpath = fullfile(fspath,basesub,'surf');
surftype = 'white';

for hh={'l','r'} % once for each hemisphere

    tic
    spath = fullfile(surfpath,sprintf('%sh.%s',hh{1},surftype));
    [~,faces] = mne_read_surface(spath);
    numberOfVerts = max(faces);
    numberOfFaces = size(faces);

    uverts = unique(faces(:)); % unique vertex numbers

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%% CREATE HASH TABLE OF ADJACENT VERTICIES
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    ht = java.util.Hashtable;
    facesduplicate = zeros(length(faces)*3, 3);

    for i = 1:length(faces)
        q = length(faces);
        % disp(num2str(i));
        facesduplicate(i,1:3) = [faces(i,1) faces(i,2) faces(i,3)];
        facesduplicate(i+q,1:3) = [faces(i,2) faces(i,1) faces(i,3)];
        facesduplicate(i+(q*2),1:3) = [faces(i,3) faces(i,2) faces(i,1)];
    end

    sortedfaces = sortrows(facesduplicate,1);

    thisface = 1;
    adjacent = [];
    for i = 1:length(sortedfaces)
        % disp(num2str(i));
        face = sortedfaces(i,1);
        if  (face == thisface)
            key = num2str(face);
            adjacent = [adjacent sortedfaces(i,2)];
            adjacent = [adjacent sortedfaces(i,3)];
        else
            unad = unique(adjacent);
            ht.put(key,unad);
            adjacent = [];
            thisface = face;


            % now continue as normall
            key = num2str(face);
            adjacent = [adjacent sortedfaces(i,2)];
            adjacent = [adjacent sortedfaces(i,3)];
        end
    end


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%% Find the adjacent vertices (some radius away from the center vertex)
    %%%% to some central vertex ('adjacents') and all the vertices inside this
    %%%% ring ('passed').
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    cmat = zeros(size(uverts,1));

    for k=uverts'
      [adjacents, passed] = getadjacent(num2str(k), radius, ht);
      for a=adjacents'
        cmat(k,a) = 1;
        cmat(a,k) = 1;
      end % for a=adjacents
    end % for k=uverts'
    
    savefile = sprintf('%sh.%s.r%d.cmat.mat',hh{1},surftype,radius);
    save(fullfile(surfpath,savefile),'cmat');
    toc
end % for hh={'l','r
