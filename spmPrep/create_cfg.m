function custom = create_cfg()
fid = fopen('repair.cfg','w');
cd('epi');
a=dir('swr*.nii');
q=size(a);
num=q(1);
fprintf(fid,'sessions: %d\n',num);
fprintf(fid,'global_mean: 1\nglobal_threshold: 9.0\nmotion_threshold: 2.0\nmotion_file_type: 0\nmotion_fname_from_image_fname: 0\n');
fprintf(fid,'#spm_file:\n');
pathtemp=pwd;
path=strcat(pathtemp,'/');
fprintf(fid,'image_dir: %s\n',path);
fprintf(fid,'motion_dir: %s\nend\n',path);
for i=1:num;
    name=a(i).name;
    fprintf(fid,'session %d image %s\n',[i name]) ;
end
b=dir('rp*');
for i = 1:num;
    name=b(i).name;
    fprintf(fid,'session %d motion %s\n',[i name]);
end
fprintf(fid,'end');
fclose(fid);
cd('..');
end