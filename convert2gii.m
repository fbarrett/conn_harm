spath = '/g5/fbarret2/fs-subjects/fsaverage5/surf/';
h = {'l','r'};
s = {'pial','white'};
e = {'Baseline','Session1'};
gstr = 'mris_convert %s %s.gii';

for hh=h
  for ss=s
    for ee=e
      sdir = dir(fullfile(spath,sprintf('%sh.%s*%s',hh{1},ss{1},ee{1})));
      if isempty(sdir), continue, end
      for ff={sdir.name}
        lpath = fullfile(spath,ff{1});
        lstr = sprintf(gstr,lpath,lpath);
        fprintf(1,'%s\n',lstr);
        [status,error] = unix(lstr);
        if status, warning(error); end
      end % ff
    end % ee
  end % ss
end % hh

