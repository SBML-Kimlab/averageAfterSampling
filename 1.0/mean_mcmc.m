function [mean_sampling, xlsxfile] = mean_mcmc(modelfile, condition, array_rxn, flux_range, dir_base)
% Make structure with mean of MCMC sampling and name of reactions and will
% make .xlsx file with original sampling values and the values normalized
% with Biomass value.
%
% USAGE:
%   mean_sampling = mean_mcmc(modelfile, condition, target_rxn, flux_range, dir_base)
%
% INPUTS:
%   modelfile:          COBRA model file with available format
%   condition:          {'auto', 'hetero'} Condition of the model
%   array_rxn:         String array of reactions to change flux
%   flux_range:         Array of the range of flux you want to use, if you set target_rxn
%                       as 'wt', flux_range wll not give any influence.
%   dir_base:           Root of base folder you want to save the result files
%
% OUTPUTS:
%   mean_sampling:      Structure with mean of MCMC sampling and name of reactions.
%   xlsxfile:           excel file containing name of reactions, sampling
%                       values, and sampling values normalized with Biomass value
%
% EXAMPLES:
%     modelfile = 'D:\##Project\13.drakei_revision\iSL771.mat';
%     dir_base = 'D:\##Project\13.drakei_revision\MCMC\';
% 
%     condition = ["auto"];
%     array_rxn = ["wt", "FDH8", "FTHFLi", "MTHFC", "MTHFD", "MTHFR5", "METR", "CODH_ACS", "GLYCL", "GLYR"];
%     flux_range = 0 : 0.1 : 5;
%     clc
%     mean_mcmc(modelfile, condition, array_rxn, flux_range, dir_base);
%
% .. Author: - Gyu Min Lee 11/29/19

    modelChange = mcmc_10times(modelfile, condition, array_rxn, flux_range, dir_base);
    
    [~,name,~] = fileparts(modelfile);
    merge_sampling = [];
    
    for target_rxn = array_rxn
        dir_condition = strcat(dir_base, condition, 'trophic');
        dir_result = strcat(dir_condition, '\', target_rxn);
        cd (dir_result)
        
        dir_mean = strcat(dir_condition, '\mean\');
        if ~exist(dir_mean,'dir')
        mkdir(dir_mean)
        addpath(dir_mean)
        end

        if ~strcmp(target_rxn, 'wt')
            for flux = flux_range
                cd (dir_result)
                check_sampling = dir (strcat(name, '_', target_rxn, '_flux_', num2str(flux), '*.mat'));
                count_sampling = size(check_sampling);
                
                if count_sampling(1) ~= 10
                    warning (sprintf ('%s : flux %s .... NOT finished 10 times.\nend',  target_rxn, num2str(flux)));
                else
                    fprintf('%s : flux %s .... finished 10 times\nNow making average ....\n',  target_rxn, num2str(flux))
                    meanfile = strcat('mean_', name, '_', target_rxn, '_flux_', num2str(flux), '.mat');
                    xlsxfile = strcat('mean_', name, '_', target_rxn, '_flux_', num2str(flux), '.xlsx');
                    cd (dir_mean)
                    if ~isfile (meanfile)
                        cell_samplingFiles = struct2cell(check_sampling);
                        cell_samplingFiles = {cell_samplingFiles{1, :}};
                        for resultfile = cell_samplingFiles
                            cd (dir_result)
                            load (string(resultfile));
                            merge_sampling = horzcat(merge_sampling, samples);
                        end
                        mean_sampling = mean(merge_sampling, 2);
                        mean_sampling = struct('mean', mean_sampling);
                        [mean_sampling(:).rxns] = modelChange.rxns;

                        cd (dir_mean)
                        save(strcat(dir_mean, meanfile), 'mean_sampling');
                        fprintf ('%s ....Saved.\n\n',  meanfile);
                        
                        nmean = size(mean_sampling.mean, 1);
                        norm_mean = zeros(nmean, 1);
                        idx_biomass = find(modelChange.c);
                        value_biomass = mean_sampling.mean(idx_biomass);
                        for i = 1 : nmean
                            norm_mean(i, 1) = mean_sampling.mean(i, 1) / value_biomass;
                            norm_mean(i, 1) = round(norm_mean(i, 1), 5);
                        end
                        merge_mean_sampling = [mean_sampling.rxns, num2cell(mean_sampling.mean), num2cell(norm_mean)];
                        writecell(merge_mean_sampling, xlsxfile, 'Sheet', 1, 'Range', 'A1')
                        fprintf ('%s ....Saved.\n\n',  xlsxfile);
                    else
                        fprintf ('%s ....Already exist.\n',  meanfile);
                        if ~isfile(xlsxfile)
                            load(meanfile);

                        nmean = size(mean_sampling.mean, 1);
                        norm_mean = zeros(nmean, 1);
                        idx_biomass = find(modelChange.c);
                        value_biomass = mean_sampling.mean(idx_biomass);
                        for i = 1 : nmean
                            norm_mean(i, 1) = mean_sampling.mean(i, 1) / value_biomass;
                            norm_mean(i, 1) = round(norm_mean(i, 1), 5);
                        end
                        merge_mean_sampling = [mean_sampling.rxns, num2cell(mean_sampling.mean), num2cell(norm_mean)];
                        writecell(merge_mean_sampling, xlsxfile, 'Sheet', 1, 'Range', 'A1')
                        fprintf ('%s ....Saved.\n\n',  xlsxfile);                 
                        else
                            fprintf ('%s ....Already exist.\n\n',  xlsxfile);
                        end           
                    end    
                end
            end
            
        elseif strcmp(target_rxn, 'wt')
            cd (dir_result)
            check_sampling = dir (strcat(name, '_', target_rxn, '_', '*.mat')); 
            count_sampling = size(check_sampling);
            if count_sampling(1) ~= 10
                warning (sprintf ('%s .... NOT finished 10 times.\nend',  target_rxn));
            else
                fprintf('%s .... finished 10 times\nNow making average ....\n',  target_rxn)
                cd (dir_mean)
                meanfile = strcat('mean_', name, '_', target_rxn, '.mat');
                xlsxfile = strcat('mean_', name, '_', target_rxn, '.xlsx');
                if ~isfile (meanfile)
                    cell_samplingFiles = struct2cell(check_sampling);
                    cell_samplingFiles = {cell_samplingFiles{1, :}};
                    for resultfile = cell_samplingFiles
                        load (string(resultfile));
                        merge_sampling = horzcat(merge_sampling, samples);
                    end
                    mean_sampling = mean(merge_sampling, 2);
                    mean_sampling = struct('mean', mean_sampling);
                    [mean_sampling(:).rxns] = modelChange.rxns;

                    save(strcat(dir_mean, meanfile), 'mean_sampling');
                    fprintf ('%s ....Saved.\n',  meanfile);
                    nmean = size(mean_sampling.mean, 1);
                    norm_mean = zeros(nmean, 1);
                    idx_biomass = find(modelChange.c);
                    value_biomass = mean_sampling.mean(idx_biomass);
                    for i = 1 : nmean
                        norm_mean(i, 1) = mean_sampling.mean(i, 1) / value_biomass;
                        norm_mean(i, 1) = round(norm_mean(i, 1), 5);
                    end
                    merge_mean_sampling = [mean_sampling.rxns, num2cell(mean_sampling.mean), num2cell(norm_mean)];
                    writecell(merge_mean_sampling, xlsxfile, 'Sheet', 1, 'Range', 'A1')
                    fprintf ('%s ....Saved.\n\n',  xlsxfile);
                else
                    fprintf ('%s ....Already exist.\n',  meanfile);
                    if ~isfile(xlsxfile)
                        load(meanfile);
                    nmean = size(mean_sampling.mean, 1);
                    norm_mean = zeros(nmean, 1);
                    idx_biomass = find(modelChange.c);
                    value_biomass = mean_sampling.mean(idx_biomass);
                    for i = 1 : nmean
                        norm_mean(i, 1) = mean_sampling.mean(i, 1) / value_biomass;
                        norm_mean(i, 1) = round(norm_mean(i, 1), 5);
                    end
                    merge_mean_sampling = [mean_sampling.rxns, num2cell(mean_sampling.mean), num2cell(norm_mean)];
                    writecell(merge_mean_sampling, xlsxfile, 'Sheet', 1, 'Range', 'A1')
                    fprintf ('%s ....Saved.\n\n',  xlsxfile);
                    else
                        fprintf ('%s ....Already exist.\n\n',  xlsxfile);                    
                    end
                end
            end
        end
    end
end



function modelChange = mcmc_10times(modelfile, condition, array_rxn, flux_range, dir_base)
% Operate 10 times of 2,000 MCMC sampling with CHRR algorithm changing
% condition of model and bounds of reaction.
%
% USAGE:
%    modelChange = mcmc_10times(modelfile, condition, array_rxn, flux_range, dir_base)
%
% INPUTS:
%   modelfile:      COBRA model file with available format
%   condition:      {'auto', 'hetero'} Condition of the model
%   array_rxn:     String array of reactions to change flux (wild type; 'wt')
%   flux_range:     Array of the range of flux you want to use, if you set target_rxn
%                   as 'wt', flux_range wll not give any influence.
%   dir_base:       Root of base folder you want to save the result files
%
% OUTPUTS:
%   modelChange:    Flux changed model used in smapling, providing a lower bound of 95% of the optimal growth rate as computed by FBA
%
% .. Author: - Gyu Min Lee 11/26/19

    initCobraToolbox;
    changeCobraSolver('ibm_cplex', 'all');
    [~,name,~] = fileparts(modelfile);
    model = readCbModel(modelfile);
    
    if ~exist(dir_base,'dir')
        mkdir(dir_base)
        addpath(dir_base)
    end
    
    switch condition
        case 'auto'
            model = changeRxnBounds( model, 'EX_h2_e', -10, 'l' );
            model = changeRxnBounds( model, 'EX_co2_e', -5, 'l' );
            model = changeRxnBounds( model, 'EX_fru_e', 0, 'l' );
        case 'hetero'
            model = changeRxnBounds( model, 'EX_h2_e', 0, 'l' );
            model = changeRxnBounds( model, 'EX_co2_e', 0, 'l' );
            model = changeRxnBounds( model, 'EX_fru_e', -2.224, 'l' );
            
    end
    dir_condition = strcat(dir_base, condition, 'trophic');
    if ~exist (dir_condition, 'dir')
        mkdir(dir_condition)
        addpath(dir_condition)
    end
    for target_rxn = array_rxn    
        dir_result = strcat(dir_condition, '\', target_rxn);
        if ~exist(dir_result,'dir')
            mkdir(dir_result)
            addpath(dir_result)
        end
        cd(dir_result)

        modelChange = model;
    
        if ~strcmp(target_rxn, 'wt')
            fprintf ('%s, %s flux from %s to %s ....operating\n\n', name, ...
            target_rxn, num2str(flux_range(1,1)), num2str(flux_range(1,end)));
            
            for flux = flux_range
                resultfile = strcat(name, '_', target_rxn, '_flux_', num2str(flux), '_', num2str(time), '.mat'); 
                
                if ~isfile(resultfile)    
                    modelChange = changeRxnBounds( modelChange, target_rxn, flux, 'b');
                    fba = optimizeCbModel(modelChange);
                    modelChange = changeRxnBounds(modelChange, 'BiomassSynthesis', 0.95 * fba.f, 'l');
                    for time = 1:10                                
                        try
                            warning('off')
                            [ ~,samples ] = sampleCbModel( modelChange );
                            warning('on')
                            fprintf ('%s : flux %s, %s time ....operate.\n',  target_rxn, num2str(flux), num2str(time));
                            save(resultfile, 'samples')
                            fprintf ('%s ....Saved.\n\n',  resultfile);    
                        catch
                            warning('on')
                            warning (sprintf ('%s : flux %s, %s time ....NOT operate.',  target_rxn, num2str(flux), num2str(time)));
                        end
                    end
                else
                    fprintf ('%s ....Already exist.\n\n',  resultfile);            
                end
            end

        elseif strcmp(target_rxn, 'wt')
            fprintf ('%s, %s ....operating\n\n', name, target_rxn);

            fba = optimizeCbModel(modelChange);
            modelChange = changeRxnBounds(modelChange, 'BiomassSynthesis', 0.95 * fba.f, 'l');
            for time = 1:10
                resultfile = strcat(name, '_', target_rxn, '_', num2str(time), '.mat'); 
                if ~isfile(resultfile)
                    try
                        warning('off')
                        [ ~,samples ] = sampleCbModel( modelChange );
                        warning('on')
                        fprintf ('%s : %s time ....operate.\n',  target_rxn, num2str(time));
                        save(resultfile, 'samples')
                        fprintf ('%s ....Saved.\n\n',  resultfile);    
                    catch
                        warning('on')
                        warning (sprintf ('%s : %s time ....NOT operate.',  target_rxn, num2str(time)));
                    end
                else
                    fprintf ('%s ....Already exist.\n\n',  resultfile);            
                end
            end
        end
    end
end  