first = which('spmPrep');
second = first(1:end-9);
third=strcat(second,'mricron/dcm2nii64');
comm=strcat('chmod a+x',{' '},third);
want=char(comm);
unix(want);
q=dir('orig');
qq=size(q);
qqq=qq(1);
if qqq==0;
    dumbVar=1;
    mkdir('orig');
    try
        movefile('*.*','orig');
    end
end
mkdir('epi');
mkdir('physio');
mkdir('hires');
mkdir('analyses');
mkdir('figures');
mkdir('asl');
mkdir('dti');
cd('analyses');
mkdir('gift_20');
mkdir('gift_70');
cd('../orig');
!cp -r *sense* ../epi
!cp -r *.log ../physio
cd('../epi')
!mv *mprage* ../hires
cd ('../orig')
command=strcat(third,{' '},'-4 y -n y -v y -g n ../orig');
wanted=char(command);
unix(wanted);
!cp -r *ASL* ../asl
!cp -r *DTI* ../dti
if dumbVar==1;
    movefile('batch.mat','..');
end