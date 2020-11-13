function [result] = code_step(permutation, behav_name, covariates_names)

permorder = 1:139;
if permutation == true
    permorder = randperm(139);
end

%behav_name = 'ambi_comm';
%covariates_names = {};
%age, sex, edu_y, n_size, comm_size, mean_comm, n_constraint, shealth, township, mmse, a, e, n, o, c, maxhead, meanhead, genderrole

%threshold for feature selection
thresh = 0.01;

%threshold for head motion
max_maxhead = 4.5;
max_meanhead = 0.5;

%threshold for social brain mask
min_social = 21;

% ----------------- INPUTS ----------------------

data = readtable("data/variables_161.csv");
load('data/all_mats_161.mat'); %load all_mats
valid = find(~isnan(data{:,behav_name}));
valid = intersect(valid, find(data{:,'maxhead'}<=max_maxhead));
valid = intersect(valid, find(data{:,'meanhead'}<=max_meanhead));
%valid_y =  intersect(valid, find(data{:,'township'} == 1));
%valid_b =  intersect(valid, find(data{:,'township'} == 2));

all_mats = all_mats(:, :, valid);
all_behav = data{valid,behav_name}; %set all_behav
all_behav = zscore(all_behav(permorder));
all_cov = data{valid, covariates_names}; %set cov

% ----------------------------------------------

no_sub = size(all_mats, 3);
no_node = size(all_mats, 1);

behav_pred_pos = zeros(no_sub,1);
behav_pred_social_pos = zeros(no_sub,1);
behav_pred_neg = zeros(no_sub,1);
behav_pred_social_neg = zeros(no_sub,1);

sum_pos_mask = zeros(no_node, no_node);
sum_neg_mask = zeros(no_node, no_node);

% ----------------------------------------------

% load social brain mask
valid_roi = [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99 120 121 122 123 124 125 126 127 128 129 130 131 132 133 134 135 136 137 138 139 140 141 142 143 144 145 146 147 148 149 150 151 152 153 154 155 156 157 158 159 160 161 162 163 164 165 166 167 168 169 170 171 172 173 174 175 176 177 178 179 180 181 182 183 184 185 186 187 188 189 190 191 192 193 194 195 196 197 198 199 200 201 202 203 204 205 206 207 208 209 210 211 212 213 214 215 216 217 218 219 220 221 222 223 224 225 226 227 228 229 230 231 232 233 234 235 257 258 259 260 261 262 263 264 265 266 267 268];
V = spm_vol(fullfile('data/shen_2mm_268_parcellation.nii'));
shenvol = spm_read_vols(V);
socialvol = spm_read_vols(spm_vol(fullfile('data/mentalizing_association-test_z_FDR_0.01.nii')));
social_cognition_k = zeros(1,268);
for i=1:268
    social_cognition_k(i) = size(intersect(find(shenvol == i), find(socialvol>0)),1);
end

social_cognition_k = social_cognition_k(valid_roi);
social_roi = find(social_cognition_k >= min_social);

social_brain_mask = zeros(size(all_mats,1),size(all_mats,1));
for i=1:no_node
    for j=1:no_node
        if or(any(i==social_roi),any(j==social_roi))
            social_brain_mask(i,j) = 1;
        end
    end
end
%social_brain_mask = 1 - social_brain_mask;

for leftout = 1:no_sub;
    %fprintf('\n Leaving out subj # %6.3f', leftout);
    
    % leave out subject from matrices and behavior
    train_mats = all_mats;
    train_mats(:, :, leftout) = [];
    train_vcts = reshape(train_mats, [], size(train_mats, 3));
    
    train_behav = all_behav;
    train_behav(leftout) = [];
    
    train_cov = all_cov;
    train_cov(leftout,:) = [];
    
    % correlate all edges with behavior using partial correlation
    if length(covariates_names) == 0
        [r_mat, p_mat] = corr(train_vcts', train_behav, 'type', 'pearson');
    else
        [r_mat, p_mat] = partialcorr(train_vcts', train_behav, train_cov);
    end
    r_mat = reshape(r_mat, no_node, no_node);
    p_mat = reshape(p_mat, no_node, no_node);
    
    % set threshold and define masks
    pos_mask = zeros(no_node, no_node);
    neg_mask = zeros(no_node, no_node);
    pos_edges = find(r_mat > 0 & p_mat < thresh);
    neg_edges = find(r_mat < 0 & p_mat < thresh);
    pos_mask(pos_edges) = 1;
    neg_mask(neg_edges) = 1;
    social_pos_mask = pos_mask .* social_brain_mask;
    social_neg_mask = neg_mask .* social_brain_mask;
    sum_pos_mask = sum_pos_mask + pos_mask;
    sum_neg_mask = sum_neg_mask + neg_mask;
    
    % get sum of all edges in TRAIN subs (divide by 2 to control for the
    % fact that matrices are symmetric
    train_sumpos = zeros(no_sub - 1, 1);
    train_sumneg = zeros(no_sub - 1, 1);
    train_social_sumpos = zeros(no_sub - 1, 1);
    train_social_sumneg = zeros(no_sub - 1, 1);

    for ss = 1:size(train_sumpos)
        train_sumpos(ss) = sum(sum(train_mats(:,:,ss).*pos_mask))/2;
        train_sumneg(ss) = sum(sum(train_mats(:,:,ss).*neg_mask))/2;
        train_social_sumpos(ss) = sum(sum(train_mats(:,:,ss).*social_pos_mask))/2;
        train_social_sumneg(ss) = sum(sum(train_mats(:,:,ss).*social_neg_mask))/2;
    end
    
    % build model on TRAIN subs
    fit_pos = polyfit(train_sumpos, train_behav,1);
    fit_neg = polyfit(train_sumneg, train_behav,1);
    fit_social_pos = polyfit(train_social_sumpos, train_behav, 1);
    fit_social_neg = polyfit(train_social_sumneg, train_behav, 1);
    
    % run model on TEST sub
    test_mat = all_mats(:,:, leftout);
    test_sumpos = sum(sum(test_mat.*pos_mask))/2;
    test_sumneg = sum(sum(test_mat.*neg_mask))/2;
    test_social_sumpos = sum(sum(test_mat.*social_pos_mask))/2;
    test_social_sumneg = sum(sum(test_mat.*social_neg_mask))/2;
    
    behav_pred_pos(leftout) = fit_pos(1) * test_sumpos + fit_pos(2);
    behav_pred_neg(leftout) = fit_neg(1) * test_sumneg + fit_neg(2);
    behav_pred_social_pos(leftout) = fit_social_pos(1)*test_social_sumpos + fit_social_pos(2);
    behav_pred_social_neg(leftout) = fit_social_neg(1)*test_social_sumneg + fit_social_neg(2);
    
end

% Prediction performance
[R_pos_social, P_pos_social] = corr(behav_pred_social_pos, all_behav);
MAE_social_pos = sum( sum( abs(behav_pred_social_pos-all_behav) ) ) / length( behav_pred_social_pos(:) );
[R_pos, P_pos] = corr(behav_pred_pos, all_behav);
MAE_pos = sum( sum( abs(behav_pred_pos-all_behav) ) ) / length( behav_pred_pos(:) );
[R_neg_social, P_neg_social] = corr(behav_pred_social_neg, all_behav);
MAE_social_neg = sum( sum( abs(behav_pred_social_neg-all_behav) ) ) / length( behav_pred_social_neg(:) );
[R_neg, P_neg] = corr(behav_pred_neg, all_behav);
MAE_neg = sum( sum( abs(behav_pred_neg-all_behav) ) ) / length( behav_pred_neg(:) );

result = table(R_pos_social,MAE_social_pos,R_pos,MAE_pos,R_neg_social,MAE_social_neg,R_neg,MAE_neg);
