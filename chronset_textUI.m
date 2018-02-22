function [on] = chronset_textUI()


fillEmpty = 1;
% chronset_textUI(params)
%[Inputs]: params is a strcuture with different fields
%
%	mandatory inputs:
%	-----------------
%	params.input_file_name 	= filename of the audiofile to be processed
%
%
%	optional inputs:
%	----------------
%	params.savepath 	= path to where the output txt file will be saved
%
%
%[Output]: this function returns the onset time of speech in 2 formats:
%          1) the onset is printed out on the screen
%          2) a txt file is saved to disc to either the default path or a
%          path specified by the user
%              
%Code intially developed by:
% F.Roux, University of Birmingham
% B, Armstrong, University of Torronto	
% Aug 2016

%% set the path to the default chronset folder
restoredefaultpath;
if isunix || ismac
	chrondir = dir('/usr/local/chronset/');
	if isempty(chrondir)
		error('search for chronset in /usr/local/ failed. please consult README.txt');
	end;
    chrondir = '/usr/local/chronset/';
end;

if ispc
    chrondir = dir('C:\Program Files\');
    if isempty(chrondir)
        error('search for chronset in /usr/local/ failed. please consult README.txt');
    end;
    chrondir = 'C:\Program Files\';
end;

addpath(genpath(chrondir));

%% get the path and filename of the input wav-file

[FILENAME, LOAD_PATHNAME, ~] = uigetfile(chrondir,'Welcome to Chronset. pick the files you wish to load','MultiSelect', 'on');
[SAVE_PATHNAME] = uigetdir(chrondir,'Thank you! Now pick a directory to save your output');

if iscell(FILENAME) <2
    dum{1} = FILENAME;
    FILENAME = dum;
    clear dum;
end;

%% load the precomputed threshods

load([chrondir,filesep,'thresholds',filesep,'greedy_optim_thresholds_BCN_final.mat']);

[thresh] = chronset_extract_thresholds(optim_data);

%% reads in the wavfile
tt = tic;
for it = 1:length(FILENAME)
    in = struct;
    fprintf('computing file\n');
    
    %added try catch to enable compatibility between older and newer
    %versions of matlab.  
    try
        [in.wav,in.FS] = wavread2([LOAD_PATHNAME,FILENAME{it}]);
    catch ME
        [in.wav,in.FS] = audioread([LOAD_PATHNAME,FILENAME{it}]);
    end
   
    if ~isempty(in.wav)        
        in.wav = in.wav(:,1);
        %replace completely empty parts of a recording with low amount of noise

        if fillEmpty == 1
            %lock random noise values for replication purposes.  
            rng(1);

            sig = in.wav;

            if ~isempty(sig(sig~=0))
                A = median(sig(sig~=0));
            else
                A = 0.01;
            end

            if ~isempty(sig(sig~=0))
                %20 percentile seems enough noise to avoid NaNs due to
                %singularity
                qt = quantile(sig(sig~=0),0.2);
            else
                qt = 0.01;
            end

            zlx = find(sig==0);

            sig(zlx) = A +qt*randn(1,length(zlx));

            in.wav = sig;
        end


        %% compute speech features
        try
            
        [feat_data] = compute_feat_data([],in);

        %% detect speech onset
        [on(it)] = detect_speech_on_and_offset(feat_data,[thresh' {0.035} {4} {0.25}]);
        
        catch ME
                disp('Error processing file.  Chronset will try to continue crushing RTs...');
                disp(getReport(ME));
                [on(it)] = NaN;
        end
            
    else
        disp('ERROR, detected empty file');
        disp(FILENAME{it});
        [on(it)] = NaN;
    end
    
        
    
    
    %% write output textfile
    fid = fopen([SAVE_PATHNAME,filesep,FILENAME{it},'_onset.txt'],'w+');
    fprintf(fid,'%s',FILENAME{it});
    fprintf(fid,'\t');
    fprintf(fid,'%s',num2str(on));
    fprintf(fid,'\n\r');
    
end;
tt = toc(tt);

fprintf('Speech onset detection complete\n');
fprintf(['Total time required:',num2str(round(tt*1e2)/1e2),' seconds \n']);
fprintf('Thank you for using CHRONSET!!!\n');
fprintf('We welcome feedback at chronset@bcbl.eu\n');
