function mrQ = mrQ_updateStructBaseDir(mrQ, old_base, new_base)
%   mrQ = mrQ_updateStructBaseDir(mrQ, old_base, new_base)
%
% For a given mrQ structure, this function will replace the base directory
% (old_base) for all file paths in the structure, with a new base directory
% (new_base) so that the struct may be used when the file is moved across
% file systems. 
%
% <old_base> must be found within the field value.
%
% INPUTS
%       mrQ         - <struct> mrQ structure, as output in 'mrQ_params.mat'
%       old_base    - <str> the base directory in the original structure
%       new_base    - <str> the base directory in the new structure
%
% OUTPUTS
%       mrQ         - <struct> Updated mrQ structure with new path structure
% 

%{
    % EXAMPLE USAGE:
    load('mrq_Params.mat');
    mrQ_newbase = mrQ_updateStructBaseDir(mrQ, '/flywheel/v0/output',
    '/scratch/mrq/verify_test_data/gear');
%}
%{
    % EXAMPLE OUTPUT:
    mrQ.maps

    ans = 

      struct with fields:

             fh: '/flywheel/v0/output/ACS10_19709-mrQ_Output/SPGR_1/AC_PC_Align_0.875_0.875_1/T1wVIP_fit.nii.gz'
        VIPpath: '/flywheel/v0/output/ACS10_19709-mrQ_Output/OutPutFiles_1/BrainMaps/VIP_map.nii.gz'
         TVpath: '/flywheel/v0/output/ACS10_19709-mrQ_Output/OutPutFiles_1/BrainMaps/TV_map.nii.gz'
        SIRpath: '/flywheel/v0/output/ACS10_19709-mrQ_Output/OutPutFiles_1/BrainMaps/SIR_map.nii.gz'
         T1path: '/flywheel/v0/output/ACS10_19709-mrQ_Output/OutPutFiles_1/BrainMaps/T1_map_Wlin.nii.gz'
         WFpath: '/flywheel/v0/output/ACS10_19709-mrQ_Output/OutPutFiles_1/BrainMaps/WF_map.nii.gz'

mrQ_newbase = mrQ_updateStructBaseDir(mrQ, '/flywheel/v0/output',
    '/scratch/mrq/verify_test_data/gear');

    mrQ_newbase.maps

    ans = 

      struct with fields:

             fh: '/scratch/mrq/verify_test_data/gear/ACS10_19709-mrQ_Output/SPGR_1/AC_PC_Align_0.875_0.875_1/T1wVIP_fit.nii.gz'
        VIPpath: '/scratch/mrq/verify_test_data/gear/ACS10_19709-mrQ_Output/OutPutFiles_1/BrainMaps/VIP_map.nii.gz'
         TVpath: '/scratch/mrq/verify_test_data/gear/ACS10_19709-mrQ_Output/OutPutFiles_1/BrainMaps/TV_map.nii.gz'
        SIRpath: '/scratch/mrq/verify_test_data/gear/ACS10_19709-mrQ_Output/OutPutFiles_1/BrainMaps/SIR_map.nii.gz'
         T1path: '/scratch/mrq/verify_test_data/gear/ACS10_19709-mrQ_Output/OutPutFiles_1/BrainMaps/T1_map_Wlin.nii.gz'
         WFpath: '/scratch/mrq/verify_test_data/gear/ACS10_19709-mrQ_Output/OutPutFiles_1/BrainMaps/WF_map.nii.gz'


%}

% TODO: Path to the mrQ_params.mat file should be enough info to set everything
%       else... 

%% Check Variables

if ~isstruct(mrQ)
    error('Please load the mrQ file before running');
end
  
if ~exist('old_base', 'var') || isempty(old_base)
    disp(mrQ.mapsDir);
    error('Please provide an old base directory');
end

if ~exist('new_base', 'var') || isempty(new_base)
    error('Please provide a new base directory');
end


%% Update mrQ struct fields

fields = fieldnames(mrQ);

% Iterate over all the fields and update the structure accordingly
for f = 1:numel(fields)
    field_val = mrQ.(fields{f});
    % Nested structs
    if isstruct(field_val)
        nested_fields = fieldnames(field_val);
        for ff = 1:numel(nested_fields)
            nested_field_val = field_val.(nested_fields{ff});
            if ischar(nested_field_val)
                start_ind= strfind(nested_field_val, old_base);
                if start_ind == 1
                    field_val.(nested_fields{ff}) = strrep(nested_field_val, old_base, new_base);
                    fprintf('\nReplaced %s with %s', nested_field_val, field_val.(nested_fields{ff}));
                end
            end
        end
        mrQ.(fields{f}) = field_val;
    % Top-level value
    elseif ischar(field_val)
        start_ind = strfind(field_val, old_base);  
        if start_ind == 1
            mrQ.(fields{f}) = strrep(field_val, old_base, new_base);
            fprintf('\nReplaced %s with %s', field_val, mrQ.(fields{f}));
        end
    end
end

end