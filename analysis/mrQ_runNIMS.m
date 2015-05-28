function mrQ_runNIMS(dir,useSUNGRID,refFile,outDir,UnderDevelop)
%mrQ_runNIMS(dir,Callproclus,refFile,outDir)
%dir - where the nifti from NIMS are.
%Callproclus use 1 when using proclus (stanfrod computing cluster)
%refFile a path to a reference image (nii.gz)
%outDir  where the output will be saved (defult is: pwd/mrQ)

   % Create the initial structure
   if notDefined('outDir') 
            outDir = fullfile(dir,'mrQ');
   end %creates the name of the output directory
   
   if ~exist(outDir,'dir'); mkdir(outDir); end
   
            mrQ = mrQ_Create(dir,[],outDir); %creates the mrQ structure

            % Set other parameters
%            mrQ = mrQ_Set(mrQ,'sub',num2str(ii));
            
            if notDefined('useSUNGRID')
                mrQ = mrQ_Set(mrQ,'sungrid',false);
            else
                mrQ = mrQ_Set(mrQ,'sungrid',useSUNGRID);
            end
            
%             mrQ = mrQ_Set(mrQ,'sungrid',1);
            mrQ = mrQ_Set(mrQ,'fieldstrength',3);

      

            % Specific arrange function for nimsfs
            mrQ = mrQ_arrangeData_nimsfs(mrQ);
            
            if ~notDefined('refFile')
                mrQ = mrQ_Set(mrQ,'ref',refFile);
                
            else
                % New input to automatically acpc align
                mrQ = mrQ_Set(mrQ,'autoacpc',1);
            end
            
            % RUN IT
            if notDefined('UnderDevelop') 
            mrQ_run(mrQ.name);
            else
            mrQ_run_N(mrQ.name);
            end
