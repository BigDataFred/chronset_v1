function [feat_data] = compute_feat_data(optp,in_data)

%% local detrending
x = locdetrend(in_data.wav,in_data.FS,[]);

movingwin = [.5 .05];% 500 ms
x = locdetrend(x,in_data.FS,movingwin);

movingwin = [.25 .025];% 250 ms
x = locdetrend(x,in_data.FS,movingwin);

movingwin = [.1 .01];% 100 ms
x = locdetrend(x,in_data.FS,movingwin);

%%
feat_data.sig = diff(x-mean(x)./std(x));
feat_data.FS = in_data.FS;
feat_data.orig = in_data.wav;
clear in_data x;

%% setup parameters for spectral analysis
params = [];
params.Fs = feat_data.FS;
params.fpass = [80 params.Fs/2];


if isempty(optp)
    optp.p1 = 0.01;%length of moving window
    optp.p2 = 500;% spectral smoothing
end;

n1 = 2^(nextpow2(.01*params.Fs)+6);
n2 = 2^nextpow2(optp.p1*params.Fs);

params.pad = (log2(n1/n2));


%movingwin = [.01 .001];
movingwin = [optp.p1 .001];


%TW = movingwin(1)*500;
TW = floor(movingwin(1)*optp.p2);

k = (2*(TW)-1);

params.tapers = [TW k];

%% spectral analysis
[feat_data.s,feat_data.t,feat_data.f] = mtspecgramc(feat_data.sig,movingwin,params);
[feat_data.ds,feat_data.t,feat_data.f] = mtdspecgramc(feat_data.sig,movingwin,[0,pi/2],params);

feat_data.tAx = 0:length(feat_data.orig)-1;
feat_data.tAx = feat_data.tAx./feat_data.FS;

%% compute the features
[feat_data.features,feat_data.syl_seg] = compute_Speech_features(feat_data);

%% apply kernel-smoothing
% changed to see if this decreases temp uncertainty addded June 18 2016
sp(1) = 20;%40;
sp(2) = 20;%80;
sp(3) = 6;%10;
sp(4) = 20;%120;
sp(5) = 20;%120;
sp(6) = 20;%120;
for it = 1:length(feat_data.features)
    [feat_data.features{it}]= apply_smoothing2features(feat_data.features{it},sp(it),'gausswin');
end;

%% normalize speeach features to 0-1 range
for it = 1:length(feat_data.features)
    
    %June 2017, bca: Fixing out of bounds errors that appear linked to
    %inf/-inf values, particularly in harmonic pitch.
    minv = min(feat_data.features{it}(isfinite(feat_data.features{it})));
    maxv = max(feat_data.features{it}(isfinite(feat_data.features{it})));
    
    %Replace the values where A==-inf with the minimum real number.
    feat_data.features{it}(feat_data.features{it}==-inf) = minv;
    %Replace the values where A==+inf with the maximum real number.
    feat_data.features{it}(feat_data.features{it}==inf)  = maxv;

    feat_data.features{it} = (feat_data.features{it} -minv )./(maxv-minv);
    
end;
