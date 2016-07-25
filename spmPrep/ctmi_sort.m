cd('Screening');
mkdir('epi');
mkdir('hires')
mkdir('analyses');
cd('analyses');
mkdir('gift_20');
mkdir('gift_70');
cd('../orig');
a=dir('RS_BOLD*');
names=a.name;
cd(names);
!~/mricron/dcm2nii64 -4 y -n y -v y -g n ../RS_BOLD*
!cp -r *.nii ../../epi
cd ('..');
b=dir('T1_MPRAGE*');
names1=b.name;
cd(names1);
!~/mricron/dcm2nii64 -4 y -n y -v y -g n ../T1_MPRAGE*
!cp -r [^co]*.nii ../../hires


