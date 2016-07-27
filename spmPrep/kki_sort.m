first = which('spmPrep');
second = first(1:end-9);
third=strcat(second,'mricron/dcm2nii64');
mkdir('epi');
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