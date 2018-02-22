function easy_visualize(input_folder,output_folder)

%should only contain a single file to process in input folder.  
%write any errors to output_file rather than dying quietly

input_folder = '/export/home/barmstrong/barmstrong/agnesa/UCDavis_onefile/'

%% Load Optimized Thresholds %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

load(['../',filesep,'thresholds',filesep,'greedy_optim_thresholds_BCN_final.mat']);
%%
[thresh] = chronset_extract_thresholds(optim_data);



%% Process Individual Wavs %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

try
    fileList = dir(input_folder);
    nf = length(fileList);
    rts = cell(nf,1);

    i=3;
    disp(['File name being processed: ' fileList(i).name]);
    
    in = struct;
    try
        [in.wav,in.FS] = wavread2([input_folder '/' fileList(i).name]);
    catch ME
        [in.wav,in.Fs] = audioread([input_folder '/' fileList(i).name]);
    end
    
    
    
    
    %[in.wav,in.FS] = wavread2([input_folder '/' fileList(i).name]);
    in.wav = in.wav(:,1);
    [feat_data] = compute_feat_data([],in);
    [on,off,feat_data] = detect_speech_on_and_offset(feat_data,[thresh' {0.035} {4} {0.25}]);
    
    %rts(i) = {[fileList(i).name, '	', num2str(round(on))]};
    plot_speech_features(feat_data, thresh);
    %visualize_speechfeatures(feat_data,[thresh' {0.035} {4} {0.25}],feat_data.finf)

    %matlabpool close;
catch ME
    
    msgString = getReport(ME);
    rts = cell(3,1);
    rts(3) = {msgString};
    
end;
