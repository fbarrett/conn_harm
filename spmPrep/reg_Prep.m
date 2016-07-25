

function space=reg_Prep(regExp)
a=dir(regExp);
num=size(a);
num=num(1);
cellA=cell(1,num);
for i=1:num;
    name=a(i).name;
    v=spm_vol(name);
    frames=length(v);
    midframe=round(frames/2);
    cellA{i}=strcat(name,',',num2str(midframe));
end
space=char(cellA);
    
    
    
