clear;
dname = pwd;
p = mfilename('fullpath');
fileDirectory = fileparts(p);
cd(fileDirectory);
pathname=strcat(pwd,'/');
filename='default_batch.mat';
copyfile(strcat(pathname,filename),dname)
curDir = pwd;
cd(dname);
if strcmp(filename,'batch.mat')==0
    movefile(filename,'batch.mat');
end
q=dir('Screening');
qq=size(q);
qqq=qq(1);
if qqq==0;
    p=dir('epi');
    pp=size(p);
    ppp=pp(1);
    if ppp==0;
        run('kki_sort.m');
        cd(dname);
    end
else;
    cd('Screening');
    p=dir('epi');
    pp=size(p);
    ppp=pp(1);
    cd('..');
    if ppp==0;
        run('ctmi_sort.m');
        cd(dname);
        cd('Screening');
        loc=strcat(dname,'/batch.mat');
        movefile(loc);
        dname=pwd;
    else
        cd(dname);
        cd('Screening');
        loc=strcat(dname,'/batch.mat');
        movefile(loc);
        dname=pwd;
    end
end
fid=fopen('dict.txt','w');
fprintf(fid,'music');
fclose(fid);
tooMuch=which('spm_jobman.m');
justRight=tooMuch(1:end-12);
tissuePath=strcat(justRight,'tpm/TPM.nii');
fid=fopen('tissue.txt','w');
fprintf(fid,'%s',tissuePath);
fclose(fid);
cd('epi');
r=dir('swr*');
rr=size(r);
rrr=rr(1);
if rrr==0
    cd('..')
    fill_batch(dname);
    clear;
    load('batch.mat');
    spm_jobman('initcfg');
    spm_jobman('run',matlabbatch);
    disp('Pre-processed files saved in epi folder.') 
    cd('epi');
else
    clear;
end
prepfiles=dir('swr*.nii');
nums=size(prepfiles);
num=nums(1);
for i=1:num
    name=prepfiles(i).name;
    v=spm_vol(name);
    frames=length(v);
    mid=round(frames/2);
%%    disp('Calculating Mean...')
%%    V = spm_vol(name);
%%    Y = spm_read_vols(V);
%%    Ysnr = mean(Y,4)./std(Y,[],4);
%%    a=Ysnr(:);
%%    noNAN=a(~isnan(a));
%%    noINF=noNAN(~isinf(noNAN));
%%    snr=mean(noINF);
%%    disp('Done')
    cd('..')
    create_cfg(name);
    art repair.cfg;
    hAllAxes = findobj(gcf,'type','axes');
    f=figure('visible','off');
    for i=1:3
        fig=hAllAxes(i);
        copyobj(fig,f);
    end
   close art;
    disp('Creating figure...')
    fig=gcf;
    fig.Name=strcat(name(1:end-4),'.fig');
    hAllAxes = findobj(gcf,'type','axes');
    meanA=hAllAxes(3);
    meanA.Position=[0.1111 .87 0.8 0.1];
    globalMean=hAllAxes(1);
    globalMean.Position=[0.1111 0.70 0.8 0.1];
    move=hAllAxes(2);
    move.Position=[.1111 0.57 0.8 0.08];
    cd('epi');
    mapping(strcat(pwd,'/',name,',',num2str(mid)));
%%    mTextBox = uicontrol('style','text');
%%    set(mTextBox,'String',strcat('SNR Mean=',num2str(snr)))
%%    mTextBox.ForegroundColor=[1 0 0];
%%    mTextBox.Position=[20 20 500 13];
    cd('../figures');
    saveas(fig,fig.Name);
    cd('../epi');
    disp('Done creating this figure')
end
    cd('../figures')
    disp('Done, Saved all figures to "figures" folder!');
