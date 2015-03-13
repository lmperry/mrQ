function [B1 resNorm PD] = mrQ_fitB1_LSQ(Res,brainMask,tr,flipAngles,outDir,M0,xform,SGE,savenow,sub,proclass)
% [B1 resNorm PD] = mrQ_fitB1_LSQ(Res,brainMask,tr,flipAngles,outDir,...
%                                 M0,xform,SGE,savenow,sub)
%
% Perform least squares fitting of B1
%
% INPUTS:
%       Res         - contains:Res{2}.im   = ok;
%                              Res{2}.name ='align_map';
%                              Res{1}.im   = SEIR_T1_1;
%                              Res{1}.name = 'target_(GS)';
%       brainMask   - Tissue mask delineating the brain region
%       tr          - TR taken from the S2 structure of aligned data
%       flipAngles  - Array of flipAngles for each scan.
%       outDir      - Ouput directory where the resulting nifti files will
%                     be saved.
%       M0          - MAP
%       xform       - Transform
%       SGE         - Option to run using SGE [default = 0]
%       savenow     - Saves the outputs to disk [default = 0]
%       sub         - Subject name for SGE call
%
%
% OUTPUTS:
%       B1
%       resNorm
%       PD
%
%
% WEB RESOURCES
%       http://white.stanford.edu/newlm/index.php/Quantitative_Imaging
%
%
% See Also:
%       mrQfit_T1M0_ver2.m


%% Check inputs

if (~exist('sub','var')|| isempty(sub)),
    sub='UN';
end

sgename=[sub '_3dB1'];

if (~exist('SGE','var')|| isempty(SGE)),
    SGE=0;
end

if (~exist('proclass','var')|| isempty(proclass))
    proclass=0;
end
    
    
if (~exist('savenow','var')|| isempty(savenow)),
    savenow=0;
end


%% Set options for optimization procedure

a=version('-date');
if str2num(a(end-3:end))>=2012
    options = optimset('Algorithm', 'levenberg-marquardt','Display', 'off','Tolx',1e-12);
else
    options =  optimset('LevenbergMarquardt','on','Display', 'off','Tolx',1e-12);%'TolF',1e-12
    
end

%options = optimset('LevenbergMarquardt','on','Display', 'off','Tolx',1e-12,'TolF',1e-12);
% we put all the relevant data in a structure call op.t thiss will make it  easyer to send it between the computer in the grid
sz=size(brainMask);
for i = 3:length(Res)
    
    tmp = Res{i}.im(brainMask);
    
    opt.s(:,i-2) = double(tmp);
    
end

opt.flipAngles = flipAngles; %(1:4);
opt.tr         = tr;
opt.wh         = find(brainMask);
opt.x0(:,1)    = M0; %./Gain(brainMask));
opt.x0(:,2)    = 1;

opt.SEIR_T1 = Res{1}.im(brainMask);
opt.outDir  = [outDir '/tmpSG'];
opt.lb      = [0 0.3];
opt.ub      = [ inf 1.7];
opt.name    = '/B1lsqVx';
jumpindex = 500;
%% let make the statment for checkes and rerunof the grid

%opt.clean=['!rm ~/sgeoutput/*' sgename '*'];

% opt.gridRun=['sgerun(' '''mrQ_fitB1PD_SGE(opt,500,jobindex);''' sgename ',1,'];
% opt.SGE_size=3000;

%% Perform the optimization (optionally using the SGE)

% USE THE SGE

    clear brainMask tmp Res M0 options
if SGE==1;
    
    % the result form the grid will be saved in a tmporery directory
    if (~exist([outDir '/tmpSG'],'dir')), mkdir([outDir '/tmpSG']);
        if proclass==1
            sgerun2('mrQ_fitB1PD_SGE(opt,500,jobindex);',sgename,1,1:ceil(length(opt.wh)/jumpindex),[],[],3000);
        else
            sgerun('mrQ_fitB1PD_SGE(opt,500,jobindex);',sgename,1,1:ceil(length(opt.wh)/jumpindex),[],[],3000);
            
        end
    else
        an1 = input( 'Unfinished SGE run found: Would you like to try and finish the existing sge run? Press 1 if yes. To start over press 0 ');
        
        % Continue existing SGE run from where we left it last time
        % we find the fit that are missing
        if an1==1
            reval=[];
            list=ls(opt.outDir);
            ch= 1:jumpindex:length(opt.wh) ;
            k=0;
            for ii=1:length(ch),
                
                ex=['_' num2str(ch(ii)) '_'];
                if length(regexp(list, ex))==0,
                    k=k+1;
                    reval(k)=(ii);
                end
            end
            
            if length(find(reval))>0
                % clean the sge output dir and run the missing fit
                eval(['!rm ~/sgeoutput/*' sgename '*']);

                 if proclass==1
               % sgerun2('mrQ_fitB1PD_SGE(opt,500,jobindex);',[sgename 'redo'],1,reval,[],[],3000);
                    for kk=1:length(reval)
                    sgerun2('mrQ_fitB1PD_SGE(opt,500,jobindex);',[sgename num2str(kk)],1,reval(kk),[],[],3000);
                    end
                else
                    sgerun('mrQ_fitB1PD_SGE(opt,500,jobindex);',sgename,1,reval,[],[],3000);
                end
            end
            
            
            % Restart the SGE processing from the beginning
        elseif an1==0,
            t = pwd;
            % cd ([ outDir '/tmpSG/'])
            cd (outDir)
            !rm -r tmpSG
            cd (t);
            
            eval(['!rm ~/sgeoutput/*' sgename '*']);
            mkdir([outDir '/tmpSG']);
            
            if proclass==1
                sgerun2('mrQ_fitB1PD_SGE(opt,500,jobindex);',sgename,1,1:ceil(length(opt.wh)/jumpindex),[],[],3000);
            else
                sgerun('mrQ_fitB1PD_SGE(opt,500,jobindex);',sgename,1,1:ceil(length(opt.wh)/jumpindex),[],[],3000);
            end
        else
            error('Unrecognized response');
        end
    end
    
   tic;
    
    %% build the data that was fit by the SGE to a B1 map
    % This loop checks if all the outputs have been saved and waits until
    % they are all done
    StopAndSave = 0;
    fNum = ceil(length(opt.wh)/jumpindex);
    tic
    while StopAndSave==0
        % List all the files that have been created from the call to the
        % grid
        list=ls(opt.outDir);
        % Check if all the files have been made.  If they are, then collect
        % all the nodes and move on.
        if length(regexp(list, '.mat'))==fNum,
            StopAndSave=1;
            
            % Loop over the nodes and collect the output
            for i=1:fNum,
                
                
                st=1 +(i-1)*jumpindex;
                ed=st+jumpindex-1;
                if ed>length(opt.wh), ed=length(opt.wh);end;
                
                name=[opt.outDir '/' opt.name '_' num2str(st) '_' num2str(ed) '.mat'];
                load (name);
                B11(st:ed)=res(2,:);
                pd1(st:ed)=res(1,:);
                resnorm1(st:ed)=resnorm;
                
            end;
            % Once we have collected all the nodes we delete the temporary
            % saved files
            t=pwd;
            cd (outDir)
            !rm -r tmpSG
            cd (t);
            eval(['!rm ~/sgeoutput/*' sgename '*'])
        else
        
        
            qStatCommand    = [' qstat | grep -i  job_' sgename(1:6)];
            [status result] = system(qStatCommand);
            tt=toc;
            if (isempty(result) && tt>60)
                % then the are no jobs running we will need to re run it.
                
                %we will rerun only the one we need
                reval=[];
                list=ls(opt.outDir);
                ch= 1:jumpindex:length(opt.wh) ;
                k=0;
                for ii=1:length(ch),
                    
                    ex=['_' num2str(ch(ii)) '_'];
                    if length(regexp(list, ex))==0,
                        k=k+1;
                        reval(k)=(ii);
                    end
                end
                
                if length(find(reval))>0
                    % clean the sge output dir and run the missing fit
                    eval(['!rm ~/sgeoutput/*' sgename '*']);
                    
                    if proclass==1
                        for kk=1:length(reval)
                        sgerun2('mrQ_fitB1PD_SGE(opt,500,jobindex);',[sgename num2str(kk)],1,reval(kk),[],[],3000);
                        end
                    else
                        sgerun('mrQ_fitB1PD_SGE(opt,500,jobindex);',sgename,1,reval,[],[],3000);
                    end
                end
                
            else
                %  keep waiting
            end
        end
        
        
        
        
        
    end
    
    % NO SGE
    %using the local computer to fit B1 and the sunGrid
else
    
 fprintf('\n Fitting the B1 map locally, this operation may be slow... \nUsing SunGridEngine would be much faster!             \n');
   
    if (~exist([outDir '/tmpSG'],'dir')), mkdir([outDir '/tmpSG']);
        jobindex=1:ceil(length(opt.wh)/jumpindex);
    else
          jobindex=[];
            list=ls(opt.outDir);
            ch= 1:jumpindex:length(opt.wh) ;
            k=0;
            for ii=1:length(ch),
                
                ex=['_' num2str(ch(ii)) '_'];
                if length(regexp(list, ex))==0,
                    k=k+1;
                    jobindex(k)=(ii);
                end
            end
    end
        
        
    if ~isempty(jobindex)
        % Run ParFor here!
        fprintf('Attempting to run jobs using parallel computing toolbox...\n');
        vistaInitParpool('performance');
        parfor i=jobindex
            mrQ_fitB1PD_SGE(opt,500,i)
        end
    end
    
    
      
    fNum = ceil(length(opt.wh)/jumpindex);
  
        % List all the files that have been created from the call to the
        % grid
        list=ls(opt.outDir);
        % Check if all the files have been made.  If they are, then collect
        % all the nodes and move on.
        
            
            % Loop over the nodes and collect the output
            for i=1:fNum,
  
                st=1 +(i-1)*jumpindex;
                ed=st+jumpindex-1;
                if ed>length(opt.wh), ed=length(opt.wh);end;
                
                name=[opt.outDir '/' opt.name '_' num2str(st) '_' num2str(ed) '.mat'];
                load (name);
                B11(st:ed)=res(2,:);
                pd1(st:ed)=res(1,:);
                resnorm1(st:ed)=resnorm;
                
            end;
        
        
    % Run the optimization without using the SGE
%     for i= 1:length(opt.wh),
%         [res(:,i), resnorm(i)] = lsqnonlin(@(par) errB1PD(par,opt.flipAngles,opt.tr,opt.s(i,:),opt.SEIR_T1(i),1,[]),opt.x0,opt.lb,opt.ub,options);
%     end
%     
%     B11(:) = res(:,2);
%     pd1(st:ed) = res(:,1);
end

B1      = zeros(sz);
PD      = B1;
resNorm = PD;

B1(opt.wh) = B11(:);
PD(opt.wh) = pd1(:);

resNorm(opt.wh) = resnorm1(:);

% Once we have collected all the nodes we delete the temporary
            % saved files
            t=pwd;
            cd (outDir)
            !rm -r tmpSG
            cd (t);
            eval(['!rm ~/sgeoutput/*' sgename '*'])

%% Save out results
%
if savenow==1
    dtiWriteNiftiWrapper(single(B1), xform, fullfile(outDir,'B1_lsq_last.nii.gz'));
    dtiWriteNiftiWrapper(single(PD), xform, fullfile(outDir,'PD_lsq_last.nii.gz'));
    dtiWriteNiftiWrapper(single(resNorm), xform, fullfile(outDir,'lsqT1PDresnorm_last.nii.gz'));
end;