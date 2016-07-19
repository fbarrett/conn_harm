# puts unsorted folders into standard format

#!/bin/bash
mkdir epi hires asl dti physio
cd orig
cp -r *sense* ../epi
cp -r *.log ../physio
cd ../epi
mv *mprage* ../hires
cd ../orig
~/mricron/dcm2nii64 -4 y -n y -v y -g n ../orig
cp -r *ASL* ../asl
cp -r *DTI* ../dti
