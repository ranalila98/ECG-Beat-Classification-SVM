% function [SVMModel, XTest, YTest] = train_svm_classifier(record_name_vec)
% %TRAIN_SVM_CLASSIFIER Train SVM model using ECG records and annotations.
% % Inputs:
% %   record_name_vec - Cell array of record names (e.g., {'100','105'})
% % Outputs:
% %   SVMModel - Trained SVM model
% %   XTest    - Test feature matrix
% %   YTest    - Test labels
% 
% %% Parameters
% fs = 360; % Sampling frequency
% baseFolder = fullfile("dataset");
% 
% %% Collect all beats and features
% beat_labels = [];
% feature_vector = [];
% 
% for i_rec = 1:numel(record_name_vec)
%     record_name = record_name_vec{i_rec};
%     dataFolder = fullfile(baseFolder, record_name);
% 
%     % Load ECG
%     matData = load(fullfile(dataFolder, record_name + "m.mat"));
%     val = matData.val;
%     ecg = val(1, :);
% 
%     % Preprocess ECG (Pan-Tompkins)
%     [ecg_m, ecg_MW] = pan_tompkins_filter(ecg, fs);
% 
%     % Extract features
%     [features, R_loc, ~, ~, ~, ~, n_beats_det, ~, ~] = extract_ecg_features(ecg_m, ecg_MW, fs);
%     feature_vector = [feature_vector; features];
% 
%     % Load annotations and assign labels
%     ant = readmatrix(fullfile(dataFolder, "annotations.csv"));
%     R_loc_act = ant(:,1);
%     beat_labels_cur = zeros(n_beats_det, 1);
%     for i = 1:n_beats_det
%         [~, ind] = min(abs(R_loc(i) - R_loc_act));
%         beat_labels_cur(i) = ant(ind, 2);
%     end
%     beat_labels = [beat_labels; beat_labels_cur];
% end
% 
% %% Stratified 70/30 split
% cv = cvpartition(beat_labels, 'HoldOut', 0.3);
% XTrain = feature_vector(training(cv), :);
% YTrain = beat_labels(training(cv));
% XTest  = feature_vector(test(cv), :);
% YTest  = beat_labels(test(cv));
% 
% %% Print dataset statistics
% fprintf("\n=== Dataset Statistics ===\n");
% fprintf("Number of beats: %d\n", numel(beat_labels));
% fprintf("Normal beats: %d (%d training, %d testing)\n", sum(beat_labels==1), sum(YTrain==1), sum(YTest==1));
% fprintf("Abnormal beats: %d (%d training, %d testing)\n", sum(beat_labels==0), sum(YTrain==0), sum(YTest==0));
% 
% %% Feature summary
% fprintf("**************************************\n")
% fprintf("** Extracted features: \n1. QS Width\n2. Pre RR Interval\n3. Post RR Interval\n4. QR Width\n5. RS Width\n6. Mean power-spectral density\n7. Area under QR\n8. Area under RS\n")
% fprintf("\n** Feature matrix created.\n")
% 
% %% Train SVM
% SVMModel = fitcsvm(XTrain, YTrain, ...
%     'KernelFunction', 'rbf', ...
%     'KernelScale', 'auto', ...
%     'BoxConstraint', Inf, ...
%     'Standardize', true, ...
%     'Solver', 'ISDA', ...
%     'ClassNames', [1, 0]);
% 
% fprintf("SVM training complete.\n");
% 
% end

function [SVMModel, XTest, YTest] = train_svm_classifier(record_name_vec)
% TRAIN_SVM_CLASSIFIER Train SVM model using ECG records and annotations.
% Inputs:
%   record_name_vec - Cell array of record names (e.g., {'100','105'})
% Outputs:
%   SVMModel - Trained SVM model
%   XTest    - Test feature matrix
%   YTest    - Test labels

% Parameters
fs = 360; % Sampling frequency
baseFolder = fullfile("dataset");

% First pass: collect normal beat segments for template
template_segments = [];

for i_rec = 1:numel(record_name_vec)
    record_name = record_name_vec{i_rec};
    dataFolder = fullfile(baseFolder, record_name);

    % Load ECG
    matData = load(fullfile(dataFolder, record_name + "m.mat"));
    ecg = matData.val(1, :);

    % Preprocess
    [ecg_m, ecg_MW] = pan_tompkins_filter(ecg, fs);

    % Quick feature pass to get beat locations
    [~, R_loc, Q_loc, S_loc, ~, ~, n_beats_det, left_ind, right_ind] = extract_ecg_features(ecg_m, ecg_MW, fs, ones(1,100));  % dummy template

    % Load annotations
    ant = readmatrix(fullfile(dataFolder, "annotations.csv"));
    R_loc_act = ant(:,1);
    labels = zeros(n_beats_det, 1);
    for i = 1:n_beats_det
        [~, ind] = min(abs(R_loc(i) - R_loc_act));
        labels(i) = ant(ind,2);
    end

    % Collect normal beat segments
    for i = 1:n_beats_det
        if labels(i) == 1  % normal
            seg = ecg_m(Q_loc(i):S_loc(i));
            if length(seg) >= 2
                seg_interp = interp1(1:length(seg), seg, ...
                    linspace(1, length(seg), 100), 'linear', 'extrap');
                template_segments(end+1,:) = seg_interp;
            end
        end
    end
end

 % === Compute class template ===
template_normal = mean(template_segments, 1);

% Second pass: collect features and labels from all records
beat_labels = [];
feature_vector = [];

for i_rec = 1:numel(record_name_vec)
    record_name = record_name_vec{i_rec};
    dataFolder = fullfile(baseFolder, record_name);

    % Load ECG
    matData = load(fullfile(dataFolder, record_name + "m.mat"));
    ecg = matData.val(1, :);

    % Preprocess
    [ecg_m, ecg_MW] = pan_tompkins_filter(ecg, fs);

    % Feature extraction (with template)
    [features, R_loc, Q_loc, S_loc, ~, ~, n_beats_det, ~, ~] = extract_ecg_features(ecg_m, ecg_MW, fs, template_normal);
    feature_vector = [feature_vector; features];

    % Load labels
    ant = readmatrix(fullfile(dataFolder, "annotations.csv"));
    R_loc_act = ant(:,1);
    beat_labels_cur = zeros(n_beats_det, 1);
    for i = 1:n_beats_det
        [~, ind] = min(abs(R_loc(i) - R_loc_act));
        beat_labels_cur(i) = ant(ind, 2);
    end
    beat_labels = [beat_labels; beat_labels_cur];
end

% Train-test split (stratified)
cv = cvpartition(beat_labels, 'HoldOut', 0.3);
XTrain = feature_vector(training(cv), :);
YTrain = beat_labels(training(cv));
XTest  = feature_vector(test(cv), :);
YTest  = beat_labels(test(cv));

% Train SVM
SVMModel = fitcsvm(XTrain, YTrain, ...
    'KernelFunction', 'rbf', ...
    'KernelScale', 'auto', ...
    'BoxConstraint', Inf, ...
    'Standardize', true, ...
    'Solver', 'ISDA', ...
    'ClassNames', [1, 0]);
save('last_training_data.mat', 'XTrain', 'YTrain', 'XTest', 'YTest');

% Summary
fprintf("\n=== Dataset Statistics ===\n");
fprintf("Total beats: %d\n", numel(beat_labels));
fprintf("Normal: %d | Abnormal: %d\n", sum(beat_labels==1), sum(beat_labels==0));
fprintf("SVM training complete.\n");
end
