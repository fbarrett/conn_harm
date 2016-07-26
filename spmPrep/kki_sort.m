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
!~/mricron/dcm2nii64 -4 y -n y -v y -g n ../orig
!cp -r *ASL* ../asl
!cp -r *DTI* ../dti

