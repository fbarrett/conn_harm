% 
%
%       mris_convert ?h.inflated ?h.inflated.gii for each subject
% 
% 


% lhemi = fullfile('/Applications/freesurfer/subjects/jed716/surf',...
% ??? = fullfile('/Applications/freesurfer/subjects/fsaverage5/surf',...
%     'rh.white.jed716.gii');
lhemi = fullfile('/Applications/freesurfer/subjects/fsaverage5/surf',...
    'lh.white.jed716.gii');
%     'lh.inflated.gii');
hemL = gifti(lhemi);

% rhemi = fullfile('/Applications/freesurfer/subjects/jed716/surf',...
rhemi = fullfile('/Applications/freesurfer/subjects/fsaverage5/surf',...
    'rh.white.jed716.gii');
%     'rh.inflated.gii');
hemR = gifti(rhemi);

surftype = 'inflated';
facecol  = [0.6 0.6 0.6];
facealpha = 1;

for vjidx=1:5
    

f=figure(vjidx); clf; set(f,'color','w','position',[1 600 780 350]);
orient(f,'landscape');
set(f,'colormap',jet)

%%% left lateral
ax(1)=axes('position',[.025 .31 .39 .66]);
p(1) = patch('Faces',hemL.faces,'Vertices',hemL.vertices,'FaceColor',facecol, ...
        'EdgeColor','none','SpecularStrength',.2,'FaceAlpha',facealpha,'SpecularExponent',200);

hold on
p(1) = patch('Faces',hemL.faces,'Vertices',hemL.vertices,'FaceVertexCData',Vj(1:10242,vjidx),...
    'FaceColor','interp','EdgeColor','none','SpecularStrength',.2,'FaceAlpha',facealpha,...
    'SpecularExponent',200);


view(-90,0);
axis off; axis image; material dull;

h(1) = light;
lightangle(h(1),-90,5); % lateral light
lighting gouraud;


%%% left medial
ax(2)=axes('position',[.245 .02 .245 .4]);
p(2) = patch('Faces',hemL.faces,'Vertices',hemL.vertices,'FaceColor',facecol, ...
        'EdgeColor','none','SpecularStrength',.2,'FaceAlpha',facealpha,'SpecularExponent',200);

hold on
p(2) = patch('Faces',hemL.faces,'Vertices',hemL.vertices,'FaceVertexCData',Vj(1:10242,vjidx),...
    'FaceColor','interp','EdgeColor','none','SpecularStrength',.2,'FaceAlpha',facealpha,...
    'SpecularExponent',200);

    
view(90,0);
axis off; axis image; material dull;

h(2) = light;
lightangle(h(2),90,5); % medial light
lighting gouraud;

%%% right lateral
ax(3)=axes('position',[.585 .31 .39 .66]);
p(3) = patch('Faces',hemR.faces,'Vertices',hemR.vertices,'FaceColor',facecol, ...
        'EdgeColor','none','SpecularStrength',.2,'FaceAlpha',facealpha,'SpecularExponent',200);

hold on
p(3) = patch('Faces',hemR.faces,'Vertices',hemR.vertices,'FaceVertexCData',Vj(1:10242,vjidx),...
    'FaceColor','interp','EdgeColor','none','SpecularStrength',.2,'FaceAlpha',facealpha,...
    'SpecularExponent',200);

view(90,0);
axis off; axis image; material dull;

h(3) = light;
lightangle(h(3),90,5); % lateral light
lighting gouraud;


%%% right medial
ax(4)=axes('position',[.51 .02 .245 .4]);
p(4) = patch('Faces',hemR.faces,'Vertices',hemR.vertices,'FaceColor',facecol, ...
        'EdgeColor','none','SpecularStrength',.2,'FaceAlpha',facealpha,'SpecularExponent',200);

hold on
p(4) = patch('Faces',hemR.faces,'Vertices',hemR.vertices,'FaceVertexCData',Vj(1:10242,vjidx),...
    'FaceColor','interp','EdgeColor','none','SpecularStrength',.2,'FaceAlpha',facealpha,...
    'SpecularExponent',200);

view(-90,0);
axis off; axis image; material dull;

h(4) = light;
lightangle(h(4),-90,5); % medial light
lighting gouraud;

%%%
drawnow;
figure(f);

% output
han(vjidx).fig = f;
han(vjidx).ax = ax;
han(vjidx).obj = p;
han(vjidx).light = h;
han(vjidx).label = {'left lateral','left medial','right lateral','right medial'};
han(vjidx).map = {};

end % for vjidx

