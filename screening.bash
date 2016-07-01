#organizes files from new scans with "screening folder"

#!/bin/bash

cd screening
mkdir epi hires
cd orig
cd RS_BOLD*
dcm2nii -4 y -n y -v y -g n ../RS_BOLD*
cp -r *.nii ../../epi
cd ../T1_MPRAGE*
dcm2nii -4 y -n y -v y -g n ../T1_MPRAGE*
cp -r [^co]*.nii ../../hires
