function calibration_thresholds_noise(f,Nper,nworker,lf)


f = 0;
Nper = 5;
nworker = 12;
lf = 1;
m='new';

%%  calibration_thresholds_SayWhen_data_16_June_2016(f,Nper,nworker,lf)
%
% Input: f 		- flag for paralell profile (default =1), must be either 0 (use local profile) or 1 (use nworker)
%	 Nper		- number of trials for each optimization (default = 350)
%	 nworker	- number of worker to be used
%	 lf		- loop factor, number of total optimization attempts = nworker*lf
%
% Ouput: optim_data 	- function returns structure with results of optimization
%
% code initially developed by Fred Roux aka FRO ( Univ. of Birmingham ) and Blair Armstrong aka BAR, June 2016

%% DEFAULTS
if nargin == 0
    Nper = 500;% number of optim iterations
    f = 1;
    nworker = 12;%128;%number of partitions
    lf = 1;
    m = 'new';
end;

%% PATH SETTINGS
%restoredefaultpath;
%addpath(genpath('~/froux/chronset/'));
%currently looks one directory up for the files...  

%% PARPOOL SETTINGS
if f ==1
   if matlabpool('size')==0
       matlabpool(nworker);%128;%128
   end;
elseif f ==0
   if matlabpool('size')==0
       matlabpool local;
   end;
end;

%% READ THE MANUAL RATINGS SAYWHEN
p2d = '/Users/froux/Downloads/female_1_rmHumanEmptyTrials_incHumanSummary/';
fc = tdfread([p2d,'summary.txt']);
fc.file = 'summary.txt';

%[data,txt,raw] = xlsread('~/froux/chronset/data/SayWhen/manual_ratings_SayWhen.xls');
%raw(1,:) = [];
%txt(1,:) = [];

%% DELETE PROBLEMATIC FILES
%data([210,218,221,370,397,429,433,470,619,1320,1783,1956,2010,3039,3141,3193,3664,4191,4290,4840],:)=[];
%txt([210,218,221,370,397,429,433,470,619,1320,1783,1956,2010,3039,3141,3193,3664,4191,4290,4840],:)=[];
%raw([210,218,221,370,397,429,433,470,619,1320,1783,1956,2010,3039,3141,3193,3664,4191,4290,4840],:)=[];

%[del_idx] = find(strcmp(raw(:,2),'..wav'));% files with bad file name
%raw(del_idx,:) = [];
%txt(del_idx,:) = [];
%data(del_idx,:) = [];

%[del_idx] = [find(isnan(data(:,5)));find(isnan(data(:,6)));find(isnan(data(:,7)));find(isnan(data(:,8)));find(isnan(data(:,9)))];%files with NaNs
%raw(del_idx,:) = [];
%txt(del_idx,:) = [];
%data(del_idx,:) = [];

%% SINGULAR VALUE DECOMPOSITION
%dum= data(:,[5:9]);
%[U,S,V] = svd(dum(:,[1,2,4]));
%pred = U(:,1)*S(1,1)*V(:,1)';

%% SWITCH BETWEEN ORIGINAL AND NEW FEATURE-DATA FORMAT
switch m
    case 'orig'
        path2featfiles = p2d;
    case 'new'
        path2featfiles = p2d;
end;

%% FILE IDs
%ID = {txt{:,3}};
%trl_n = [raw{:,4}];

trl_n = 1:size(fc.x03_woubility_u_1157_day20x2Dlanguage_switch_I_sound_recording0,1);

ID = fc.x03_woubility_u_1157_day20x2Dlanguage_switch_I_sound_recording0;
ID3 = cell(length(ID(:,1)),1);

for i =1:length(ID3)
    ID3(i) = {ID(i,:)};
    ix = regexp(ID3{i},'.wav');
    ID3{i}(ix:end) = [];
end
ID = ID3;

pred = fc.x333;

if length(pred) ~= size(ID,1)
    error('number of files must match');
end;

ID2 = cell(length(ID),1);
sel_idx = zeros(length(ID),1);
k = 0;
for jt = 1:length(ID)
    
    switch m
        case 'orig'
            chck = dir([path2featfiles,ID{jt},'.',num2str(trl_n(jt)),'.mat']);
            [id] = [raw{jt,3},'.',num2str(raw{jt,4}),'.mat']; 
        case 'new'
            chck = dir([path2featfiles,ID{jt},'.',num2str(trl_n(jt)),'.mat']);
            %chck = dir([path2featfiles,ID{jt},'.',num2str(trl_n(jt)),'*.mat']);
            if sign(length(chck)-1)==1
                return;
            end;
            if ~isempty(chck)
                d = chck.name([regexp(chck.name,'_')+1:regexp(chck.name,'.mat')-1]);
                [id] = [raw{jt,3},'.',num2str(raw{jt,4}),'_',d,'.mat'];
            end;
        case 'Blairtron'
            chck = dir([path2featfiles,ID{jt},'.mat']);
            [id] = [ID{jt},'.mat']; 
    end;  
    
    if ~isempty(chck)
        if strcmp(id,chck.name)
            k = k+1;
            ID2(k) = ID(jt);
            sel_idx(k) = jt;
        end;
    end;
end;
if isempty(ID2)
    error('empty matrix detected');
end;

ID2(k+1:end) = [];
sel_idx(k+1:end) = [];
trl_n = trl_n(sel_idx);

chck = strcmp(ID2,ID(sel_idx)');
if any(chck==0)
    error('error number of files does not match');
end;

for jt = 1:length(sel_idx)
    
    switch m
        case 'orig'
            chck = dir([path2featfiles,raw{sel_idx(jt),3},'.',num2str(raw{sel_idx(jt),4}),'.mat']);
            id = chck.name;
            id2 = [ID2{jt},'.',num2str(trl_n(jt)),'.mat'];
        case 'new'
            chck = dir([path2featfiles,raw{sel_idx(jt),3},'.',num2str(raw{sel_idx(jt),4}),'_*.mat']);
            id = chck.name;
            d = chck.name([regexp(chck.name,'_')+1:regexp(chck.name,'.mat')-1]);
            id2 = [ID2{jt},'.',num2str(trl_n(jt)),'_',d,'.mat'];
        case 'Blairtron'
            chck = dir([path2featfiles,ID{jt},'.mat']);
            id = chck.name;
            id2 = id;
    end;
    
    if ~strcmp(id,id2) 
        error('file assignment does not match');
    end;
end;
%%
switch m
    case 'new'
        o1 = load([path2featfiles,'origID.mat']);
        if ~isequal(o1.ID2,ID2) || ~isequal(o1.sel_idx,sel_idx) || ~isequal(o1.ID,ID)
            error('wrong file assignment');
        end;
    case 'Blairtron'
        %do nothing
end;
%%
dat = cell(length(ID2),2,2);
parfor jt = 1:length(ID2)
    
    switch m
        case 'orig'
            dum =load([path2featfiles,ID2{jt},'.',num2str(trl_n(jt)),'.mat']);
            dat(jt,:,:) = {dum.savedata dum.savedata;dum.savedata dum.savedata};
        case 'new'
            chck = dir([path2featfiles,ID2{jt},'.',num2str(trl_n(jt)),'_*.mat']);
            dum = load([path2featfiles,chck.name]);
            dat(jt,:,:) = [{0} dum.savedata(1,2);{0} dum.savedata(2,2)];
            
%             dat(jt,1,1) = dum.savedata(1,1);
%             dat(jt,1,2) = dum.savedata(1,2);
%             dat(jt,2,1) = dum.savedata(2,1);
%             dat(jt,2,2) = dum.savedata(2,2);
        case 'Blairtron'
            dum =load([path2featfiles,ID2{jt},'.mat']);
            dat(jt,:,:) = {dum.savedata};
    end;
    
end;
clear dum;
%%
Y = mean(pred(sel_idx,:),2);

outL = find(sign(Y-2000)==1);
Y(outL) = [];
dat(outL,:,:) = [];

if length(Y) ~= length(dat)
    error('vactor must be same length');
end;
%%
% number of partitions training vs test
if ( f == 1 )
    Ntrl = matlabpool('size')*lf;
    
    %starting values for thresholds
    itresh = cell(10,1);
    itresh{1} = .1;%amplitude
    itresh{2} = .9;%wiener entropy
    itresh{3} = .1;%spectral change
    itresh{4} = .1;% amplitude modulation
    itresh{5} = .9;%frequency modulation
    itresh{6} = .1;%goodness of pitch
    
    %%added June 13 2016
    itresh{7}  = .005;%syl length
    itresh{8}  = 4;%number of simult active features
    
    itresh{9} = 1;%sliding window size
    itresh{10} = 2;%smoothing
    
    nfeat = length(itresh);
    
    % histroy
    hist_e = zeros(Ntrl,Nper,1);
    hist_o = zeros(Ntrl,Nper,nfeat);
    hist_t = zeros(Ntrl,Nper,nfeat);
    test_e = zeros(Ntrl,Nper,1);
    init_mle = zeros(Ntrl,Nper,1);
    
    trck_ml1 = zeros(Ntrl,Nper,1);
    trck_ml2 = zeros(Ntrl,Nper,1);
    
    ei_training = zeros(Ntrl,1);
    ei_test = zeros(Ntrl,1);
    
    % freeze point step size
    fp = 50;
    
    %omega parameters
    omega_orig1 = 0.05*ones(6,1);
    if sign(length(itresh)-6) ==1
        omega_orig1(7:10) = [itresh{7:10}];
    end;
    
    omega_scale = 1;
    
    %rate parameters
    rdec = 0.5;
    rinc = 1.1;
    
    % training/test partitioning %
    test_pct = 20;
        %%
    s_t = tic;
    parfor ot = 1:Ntrl

        %reset omega
            [omega] = omega_orig1;
            
            % median manual scores
            [mY1] = median(Y,2)';
            
            %parameter space
            [param_space]   =  repmat({[0 1]},[6 1]);
            
            %added June 13 2016
            if sign(length(itresh)-6) ==1
                
                param_space{7}      = [.005 .05];
                param_space{8}      = [3    5];                
                param_space{9}  = [1   2];
                param_space{10}  = [2   2];
                
            end;
            
            nchck = 0;
            % generate the partition of the training and test data
            idx = randperm(length(dat));
            idx = idx(1:round(length(dat)/100*test_pct));
            [test_idx] =  idx;
            [training_idx] = setdiff(1:length(dat),idx);
            
            %onsets for training data (initial guess treshold values)
            on1 = zeros(length(dat),1);
            if sign(nfeat-6)==1
                for it = 1:length(dat)
                    [on1(it)] =  detect_speech_on_and_offset(dat{it,itresh{9},itresh{10}},itresh);
                end;
            else
                for it = 1:length(dat)
                    [on1(it)] =  detect_speech_on_and_offset(dat{it,1,1},[itresh{:} {.035} {4}]);
                end;
            end;
            
            %         if any(isnan(on1))
            %             error('initial seed must be integer');
            %         end;
            
            
            %[mle1] = mle(on1(training_idx)-mY1(training_idx)');%mle for training data
            C = mY1(training_idx)';
            X = on1(training_idx);
            [~,~,r1,~,~] = regress(C,[ones(size(X)) X]);
            [mle1] = mle(r1);
            ei_training(ot) = mle1(2);
            
            %[mle2] = mle(on1(test_idx)-mY1(test_idx)');% mle for test data
            C = mY1(test_idx)';
            X = on1(test_idx);
            [~,~,r2,~,~] = regress(C,[ones(size(X)) X]);
            [mle2] = mle(r2);
            ei_test(ot) = mle2(2);
            
            [test_ref] = mle2(2);
            
            [ci1] = mle1(2);% save the std of the training mle
            
            if ~isnan(ci1) && ~any(isnan(on1(training_idx)-mY1(training_idx)'))
                
                % reference parameters
                [ref_ci] = ci1;% mle for intial values
                [ref_tresh1] = itresh;% initial treshold values
                
                [d_e] = zeros(Nper,1);% track history of mle over iterations
                
                % loop over optimization-iterations
                for kt = 1:Nper
                    
                    % randomly pick a feature         
                    sel = randperm(nfeat);
                    sel = sel(1);
                     
                    % update the treshold values
                    temp1 = ref_tresh1;
                    temp2 = ref_tresh1;
                    
                    % apply positive omega -increase temperature
                    if ismember(sel,1:6)
                        if sign((temp1{sel}+omega(sel))-max(param_space{sel}))==-1
                            temp1{sel} = temp1{sel}+omega(sel);
                        end;
                    end;
                    
                    if sign(length(itresh)-6) ==1
                        
                        if ( sel==7 )
                            if sign((temp1{sel}+.001)-max(param_space{sel}))==-1
                                temp1{sel} = temp1{sel}+.001;
                            end;
                        end;
                        
                        if ismember(sel,8:10)
                            if sign((temp1{sel}+1)-max(param_space{sel}))==-1 || sign((temp1{sel}+1)-max(param_space{sel}))== 0
                                temp1{sel} = temp1{sel}+1;
                            end;
                        end;
                    end;
                    
                    %compute onsets
                    on_a = zeros(length(dat),1);
                    if sign(nfeat-6)==1
                        for it = 1:length(dat)
                            [on_a(it)] =  detect_speech_on_and_offset(dat{it,temp1{9},temp1{10}},temp1);
                        end;
                    else
                        for it = 1:length(dat)
                            [on_a(it)] =  detect_speech_on_and_offset(dat{it,1,1},[temp1{:} {.035} {4}]);
                        end;
                    end;
                    
                    %                 if any(isnan(on_a))
                    %                     error('onset a must be integer');
                    %                 end;
                    
                    % estimate mle for positive temperature change
                    %ep = mle(on_a(training_idx)-mY1(training_idx)');%mle for training data
                    [~,~,r,~,~] = regress(mY1(training_idx)',[ones(size(on_a(training_idx))) on_a(training_idx)]);
                    ep = mle(r);
                    ci2_a = ep(2);% save the std
                    
                    trck_ml1(ot,kt) = ep(2);
                    
                    % modified June 13 2016
                    % apply negative omega - decrease temperature
                    if ismember(sel,1:6)
                        if sign((temp2{sel}-omega(sel))-min(param_space{sel}))==1
                            temp2{sel} = temp2{sel}-omega(sel);
                        end;
                    end;
                    
                    if sign(length(itresh)-6) ==1     
                        
                        if ( sel == 7)
                            if sign((temp2{sel}-.001)-min(param_space{sel}))==1
                                temp2{sel} = temp2{sel}-.001;
                            end;
                        end;
                        
                        if ismember(sel,8:10)
                            if (sign((temp2{sel}-1)-min(param_space{sel}))==1) || (sign((temp2{sel}-1)-min(param_space{sel}))== 0)
                                temp2{sel} = temp2{sel}-1;
                            end;
                        end;
                        
                    end;
                    
                    %compute onsets
                    on_b = zeros(length(dat),1);
                    if sign(nfeat-6)==1
                        for it = 1:length(dat)
                            [on_b(it)] =  detect_speech_on_and_offset(dat{it,temp2{9},temp2{10}},temp2);
                        end;
                    else
                        for it = 1:length(dat)
                            [on_b(it)] =  detect_speech_on_and_offset(dat{it,1,1},[temp2{:} {.035} {4}]);
                        end;
                    end;
                    
                    %                 if any(isnan(on_b))
                    %                     error('onset b seed must be integer');
                    %                 end;
                    
                    % estimate mle for negative temperature change
                    %ep = mle(on_b(training_idx)-mY1(training_idx)');%training
                    [~,~,r,~,~] = regress(mY1(training_idx)',[ones(size(on_b(training_idx))) on_b(training_idx)]);
                    ep = mle(r);
                    ci2_b = ep(2);% save the std
                    
                    trck_ml2(ot,kt) = ep(2);
                    
                    % chose change direction
                    if sign(ci2_a - ci2_b)==-1 % if positive temperature reduces mle
                        gd = ci2_a;%positive change
                        temp = temp1;
                        on1 = on_a;
                    else
                        gd = ci2_b;%negative change
                        temp = temp2;
                        on1= on_b;
                    end;
                    
                    x = [0 1];draw = randperm(2);x = x(draw(1));%draw random num
                    
                    if ( ~any(isnan(on1(training_idx)-mY1(training_idx)')) && sign(ref_ci-gd) == 1 ) || ( ( ~any(isnan(on1(training_idx)-mY1(training_idx)')) && sign(ref_ci-gd) == 0 ) && ( x==1 ) )
                        ref_ci = gd;% set new reference for mle
                        ref_tresh1 = temp;% set ne reference for treshold
                        hist_e(ot,kt) = ref_ci;% record mle history
                        omega(sel) = omega(sel)*rinc;% apply rate increment to omega
                        
                        %compute onsets test
                        test_ep = mle(on1(test_idx)-mY1(test_idx)');%mle for test data
                        test_e(ot,kt) = test_ep(2);%keep track of mle for test data
                        test_ref = test_e(ot,kt);
                    else
                        hist_e(ot,kt) = ref_ci;
                        omega(sel) = omega(sel)*rdec;% apply rate decrement to omega
                        test_e(ot,kt) = test_ref;% record mle history
                    end;
                    
                    d_e(kt) =  ref_ci;
                    
                    %freeze point
                    if mod(kt,fp) == 0
                        
                        dx = diff(d_e((kt-fp)+1:kt));
                        if max(dx) == 0 % if no change has happened over step size
                            omega = omega./omega_scale;% scale omega
                        end;
                        
                    end;
                    
                    % keep track of omega
                    hist_o(ot,kt,:) = omega;
                    hist_t(ot,kt,:) = [ref_tresh1{:}];
                    
                end;
            end;            
        
    end;
else
    Ntrl = 1;
    
    %starting values for thresholds
    itresh = cell(6,1);
    itresh{1} = .1;%amplitude
    itresh{2} = .9;%wiener entropy
    itresh{3} = .1;%spectral change
    itresh{4} = .1;% amplitude modulation
    itresh{5} = .9;%frequency modulation
    itresh{6} = .1;%goodness of pitch
    
    % histroy
    hist_e = zeros(Ntrl,Nper,1);
    hist_o = zeros(Ntrl,Nper,6);
    hist_t = zeros(Ntrl,Nper,6);
    test_e = zeros(Ntrl,Nper,1);
    init_mle = zeros(Ntrl,Nper,1);
    
    trck_ml1 = zeros(Ntrl,Nper,1);
    trck_ml2 = zeros(Ntrl,Nper,1);
    
    ei_training = zeros(Ntrl,1);
    ei_test = zeros(Ntrl,1);
    
    % freeze point step size
    fp = 50;
    
    %omega parameters
    omega_orig1 = 0.05*ones(6,1);
    omega_scale = 1;
    
    %rate parameters
    rdec = 0.5;
    rinc = 1.1;
    
    % training/test partitioning %
    test_pct = 20;
    
    %Y = Y(sel_idx,:);
    %%
    s_t = tic;
    for ot = 1:Ntrl
        %reset omega
        [omega] = omega_orig1;
        
        % median manual scores
        [mY1] = mean(Y,2)';
        
        %parameter space
        [param_space] =  repmat({[0 1]},[6 1]);
        
        nchck = 0;
        % generate the partition of the training and test data
        idx = randperm(length(dat));
        idx = idx(1:round(length(dat)/100*test_pct));
        [test_idx] =  idx;
        [training_idx] = setdiff(1:length(dat),idx);
        
        %onsets for training data (initial guess treshold values)
        on1 = zeros(length(dat),1);
        parfor it = 1:length(dat)
            [on1(it)] =  detect_speech_on_and_offset(dat{it},itresh,mY1(it));
            %[on1(it)] =  detect_speech_on_and_offset(dat{it},itresh);
        end;
        
        %         if any(isnan(on1))
        %             error('initial seed must be integer');
        %         end;
        
        %[mle1] = mle(on1(training_idx)-mY1(training_idx)');%mle for training data
        C = mY1(training_idx)';
        X = on1(training_idx);
        [~,~,r1,~,~] = regress(C,[ones(size(X)) X]);
        [mle1] = mle(r1);
        ei_training(ot) = mle1(2);
        
        %[mle2] = mle(on1(test_idx)-mY1(test_idx)');% mle for test data
        C = mY1(test_idx)';
        X = on1(test_idx);
        [~,~,r2,~,~] = regress(C,[ones(size(X)) X]);
        [mle2] = mle(r2);
        ei_test(ot) = mle2(2);
        
        [test_ref] = mle2(2);
        
        [ci1] = mle1(2);% save the std of the training mle
        
        if ~isnan(ci1) && ~any(isnan(on1(training_idx)-mY1(training_idx)'))
            
            % reference parameters
            [ref_ci] = ci1;% mle for intial values
            [ref_tresh1] = itresh;% initial treshold values
            
            [d_e] = zeros(Nper,1);% track history of mle over iterations
            
            % loop over optimization-iterations
            for kt = 1:Nper
                
                % randomly pick a feature
                sel = randperm(6);
                sel = sel(1);
                
                % update the treshold values
                temp1 = ref_tresh1;
                temp2 = ref_tresh1;
                
                % apply positive omega -increase temperature
                if sign((temp1{sel}+omega(sel))-max(param_space{sel}))==-1
                    temp1{sel} = temp1{sel}+omega(sel);
                end;
                
                %compute onsets
                on_a = zeros(length(dat),1);
                parfor it = 1:length(dat)
                    [on_a(it)] =  detect_speech_on_and_offset(dat{it},temp1,mY1(it));
                    %[on_a(it)] =  detect_speech_on_and_offset(dat{it},temp1);
                end;
                
                %                 if any(isnan(on_a))
                %                     error('onset a must be integer');
                %                 end;
                
                % estimate mle for positive temperature change
                %ep = mle(on_a(training_idx)-mY1(training_idx)');%mle for training data
                [~,~,r,~,~] = regress(mY1(training_idx)',[ones(size(on_a(training_idx))) on_a(training_idx)]);
                ep = mle(r);
                ci2_a = ep(2);% save the std
                
                trck_ml1(ot,kt) = ep(2);
                
                % apply negative omega - decrease temperature
                if sign((temp2{sel}-omega(sel))-min(param_space{sel}))==1
                    temp2{sel} = temp2{sel}-omega(sel);
                end;
                
                %compute onsets
                on_b = zeros(length(dat),1);
                parfor it = 1:length(dat)
                    [on_b(it)] =  detect_speech_on_and_offset(dat{it},temp2,mY1(it));
                    %[on_b(it)] =  detect_speech_on_and_offset(dat{it},temp2);
                    
                end;
                
                %                 if any(isnan(on_b))
                %                     error('onset b seed must be integer');
                %                 end;
                
                % estimate mle for negative temperature change
                %ep = mle(on_b(training_idx)-mY1(training_idx)');%training
                [~,~,r,~,~] = regress(mY1(training_idx)',[ones(size(on_b(training_idx))) on_b(training_idx)]);
                ep = mle(r);
                ci2_b = ep(2);% save the std
                
                trck_ml2(ot,kt) = ep(2);
                
                % chose change direction
                if sign(ci2_a - ci2_b)==-1 % if positive temperature reduces mle
                    gd = ci2_a;%positive change
                    temp = temp1;
                    on1 = on_a;
                else
                    gd = ci2_b;%negative change
                    temp = temp2;
                    on1= on_b;
                end;
                
                if ~any(isnan(on1(training_idx)-mY1(training_idx)')) && sign(ref_ci-gd) == 1
                    ref_ci = gd;% set new reference for mle
                    ref_tresh1 = temp;% set ne reference for treshold
                    hist_e(ot,kt) = ref_ci;% record mle history
                    omega(sel) = omega(sel)*rinc;% apply rate increment to omega
                    
                    %compute onsets test
                    test_ep = mle(on1(test_idx)-mY1(test_idx)');%mle for test data
                    test_e(ot,kt) = test_ep(2);%keep track of mle for test data
                    test_ref = test_e(ot,kt);
                else
                    hist_e(ot,kt) = ref_ci;
                    omega(sel) = omega(sel)*rdec;% apply rate decrement to omega
                    test_e(ot,kt) = test_ref;% record mle history
                end;
                
                d_e(kt) =  ref_ci;
                
                %freeze point
                if mod(kt,fp) == 0
                    
                    dx = diff(d_e((kt-fp)+1:kt));
                    if max(dx) == 0 % if no change has happened over step size
                        omega = omega./omega_scale;% scale omega
                    end;
                    
                end;
                
                % keep track of omega
                hist_o(ot,kt,:) = omega;
                hist_t(ot,kt,:) = [ref_tresh1{:}];
                
            end;
        end;
    end;
end;
%%
optim_data = struct;

optim_data.fp = fp;
optim_data.omega_orig = omega_orig1;
optim_data.omega_scale = omega_scale;
optim_data.rdec = rdec;
optim_data.rinc = rinc;
optim_data.test_pct =test_pct;
optim_data.Nruns = Ntrl;
optim_data.Niter = Nper;

% history of initial threshold values
optim_data.itresh = itresh;
% history of mle for training data
optim_data.hist_e = hist_e;clear hist_e;
% history of mle for test data
optim_data.test_e = test_e;clear test_e;
% history of threshold
optim_data.hist_t = hist_t;clear hist_t;
% history of omega
optim_data.hist_o = hist_o;clear hist_o;
% initial mle for training data
optim_data.ei_training = ei_training;clear ei_training;
% initial mle for test data
optim_data.ei_test = ei_test;clear ei_test;
%%
path2files = '/bcbl/home/home_a-f/froux/chronset/thresholds/';
save([path2files,'greedy_optim_NP_data_Noise_',date,'.mat'],'optim_data');
%%
matlabpool('close');
















