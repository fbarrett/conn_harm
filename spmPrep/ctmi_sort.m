first = which('spmPrep');
second = first(1:end-9);
third=strcat(second,'mricron/dcm2nii64');
cd('Screening');
mkdir('epi');
mkdir('hires')
mkdir('analyses');
mkdir('figures');
cd('analyses');
mkdir('gift_20');
mkdir('gift_70');
cd('../orig');
fourth=dir('RS_BOLD*');
fifth=fourth.name;
cd(fifth);
com1=strcat(third,{' '},'-4 y -n y -v y -g n ../RS_BOLD*');
unix(char(com1));
!cp -r *.nii ../../epi
cd ('..');
b=dir('T1_MPRAGE*');
names1=b.name;
cd(names1);
com2=strcat(third,{' '},'-4 y -n y -v y -g n ../T1_MPRAGE*');
unix(char(com2));
!cp -r [^co]*.nii ../../hires