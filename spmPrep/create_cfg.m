function custom = create_cfg(name)
fid = fopen('repair.cfg','w');
cd('epi');
fprintf(fid,'sessions: 1\n');
fprintf(fid,'global_mean: 1\nglobal_threshold: 9.0\nmotion_threshold: 2.0\nmotion_file_type: 0\nmotion_fname_from_image_fname: 0\n');
fprintf(fid,'#spm_file:\n');
pathtemp=pwd;
path=strcat(pathtemp,'/');
fprintf(fid,'image_dir: %s\n',path);
fprintf(fid,'motion_dir: %s\nend\n',path);
fprintf(fid,'session 1 image %s\n',name);
lessName=name(4:end-3);
motion=strcat('rp_',lessName,'txt');
fprintf(fid,'session 1 motion %s\n',motion);
fprintf(fid,'end');
fclose(fid);
cd('..');
end