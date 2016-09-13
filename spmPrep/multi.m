function multiples = multi(input)
cd(input);
q=0;
folders=dir2();
temp=size(folders);
amt=temp(1);
i=1;
while (i<=amt && q==0)
    tempname=folders(i).name;
    tempSize=size(tempname);
    realSize=tempSize(2);
    if realSize>4
        ext=tempname(end-3:end);
        if strcmp(tempname,'orig')==1 || strcmp(tempname,'Screening')==1 || strcmp(ext,'.nii')==1
            q=1;
            multiPrep;
            cd('..');
        end
    else
        if strcmp(tempname,'orig')==1 || strcmp(tempname,'Screening')==1
            q=1;
            multiPrep
            cd('..');
        end
    end
    i=i+1;
end
 
  
if q==0;
    for i=1:amt
        cd(folders(i).name)
        multi(pwd);
    end
    cd('..');
end
end
    
