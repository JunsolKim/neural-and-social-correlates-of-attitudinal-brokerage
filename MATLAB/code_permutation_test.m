behav_name_list = {'ambi_comm', 'sd_comm'};
covariates_list = {{},{'age','sex'}, {'age','sex','edu_y'}, {'age','sex','n_size'}, {'age','sex','mean_comm'}, {'age','sex','n_constraint'}, {'age','sex','betweenness_z'}, {'age','sex','closeness_z'}, {'age','sex','eigenvector_z'}, {'age','sex','mmse'}, {'age','sex','shealth'}, {'age','sex','a'}, {'age','sex','e'}, {'age','sex','n'}, {'age','sex','o'}, {'age','sex','c'},{'age','sex','genderrole'},{'age','sex','township'},{'age','sex','maxhead','meanhead'}};

for v=1:length(behav_name_list)
    for i=1:length(covariates_list)
        behav_name = behav_name_list{v};
        covariates = covariates_list{i};
        tic
        result = code_step(false, behav_name, covariates);
        parfor j=1:1000
            disp(append(behav_name, " ", string(j)))
            result = [result; code_step(true, behav_name, covariates)];
        end
        toc
        writetable(result,append("results/permuted_results_",behav_name,string(i),".csv"));
    end
end