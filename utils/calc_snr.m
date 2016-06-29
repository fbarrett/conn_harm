function Ysnr = calc_snr(volume)

% calculate Signal-to-Noise Ratio (SNR) for a given image on disk
% 
%       Ysnr = calc_snr(volume)
% 
% volume - images for which you want to calculate SNR. This can be a
%   path to a 4D NifTI on disk, a character matrix of paths to individual
%   volumes of a NifTI or Analyze set (hdr/img), or an actual 4D matrix.
% Ysnr  - a 3D SNR map
% 
% FB 2016.06.29 <fbarrett@jhu.edu>

if ischar(volume) && exist(volume,'file')
  % is spm on the path?
  if ~exist('spm_vol','func')
    error('SPM not loaded onto the path .. please load SPM\n');
  end

  % load the file
  V = spm_vol(volume);
  Y = spm_read_vols(V);
elseif isdouble(volume) && ndims(volume) == 4
  % the input is the 4D data
  Y = volume;
else
  % can't identify the input
  error(['unknown format for ''volume''. Needs to be either a path to '...
      'a 4D dataset, or an actual 4D dataset (e.g. output from spm_read'...
      '_vols()\n']);
end

% calculate, return SNR image
Ysnr = mean(Y,4)./std(Y,[],4);