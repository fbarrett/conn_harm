function map=mapping(img)
%%prepoced row
Vepi = spm_vol(img);
Yepi = spm_read_vols(Vepi);
si=size(Yepi);
ax1=subplot(5,3,7);
b=squeeze(Yepi(round((si(1))/2),:,:)); %sagittal plane
b=imrotate(b,90);
imagesc(b);
colormap(ax1,gray);
title('Preprocessed Sagittal Plane')
set(gca,'XTickLabel','');
set(gca,'YTickLabel','');
ax2=subplot(5,3,8);
c=squeeze(Yepi(:,round((si(2))/2),:)); %coronal plane
c=imrotate(c,90);
imagesc(c);
colormap(ax2,gray);
title('Preprocessed Coronal Plane');
set(gca,'XTickLabel','');
set(gca,'YTickLabel','');
ax3=subplot(5,3,9);
d=squeeze(Yepi(:,:,round((si(3))/2))); %axial plane
imagesc(d);
colormap(ax3,gray);
title('Preprocessed Axial Plane');
set(gca,'XTickLabel','');
set(gca,'YTickLabel','');

%% hires row
cd('../hires');
highres=dir('*mprage*.nii');
if length(highres)==1;
    hires=highres.name;
else;
    shortestNum=length(highres(1).name);
    shortestName=highres(1).name;
    for i=1:length(highres);
        cur=length(highres(i).name);
        if cur<shortestNum;
            shortestNum=length(highres(i).name);
            shortestName=highres(i).name;
        end
    end
    hires=shortestName;
end
Vepi = spm_vol(hires);
Yepi = spm_read_vols(Vepi);
si=size(Yepi);
ax1=subplot(5,3,10);
b=squeeze(Yepi(round((si(1))/2),:,:)); %sagittal plane
b=imrotate(b,90);
imagesc(b);
colormap(ax1,gray);
title('Highres Sagittal Plane')
set(gca,'XTickLabel','');
set(gca,'YTickLabel','');
ax2=subplot(5,3,11);
c=squeeze(Yepi(:,round((si(2))/2),:)); %coronal plane
c=imrotate(c,90);
imagesc(c);
colormap(ax2,gray)
title('Highres Coronal Plane');
set(gca,'XTickLabel','');
set(gca,'YTickLabel','');
ax3=subplot(5,3,12);
d=squeeze(Yepi(:,:,round((si(3))/2))); %axial plane
imagesc(d);
colormap(ax3,gray);
title('Highres Axial Plane');
set(gca,'XTickLabel','');
set(gca,'YTickLabel','');
cd('../epi');

%% vol_check row
subplot(5,3,13:15);
q=pwd;
len=length(pwd)+5;
V = spm_vol(img(len:end));
Y = spm_read_vols(V);
vmat = mean(Y,1);
vmat = squeeze(mean(vmat,2));
imagesc(vmat);
colormap(jet);
set(gca,'xtick',0:10:size(Y,4));
ylabel('Slice#');
xlabel('Volume#');

end