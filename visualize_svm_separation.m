function visualize_svm_separation(X, Y, model_name)
% VISUALIZE_SVM_SEPARATION - Project features to 2D using PCA or t-SNE
% and visualize class separation between Normal and Abnormal

% Inputs:
%   X - Feature matrix (N x D)
%   Y - Labels (N x 1), 1: normal, 0: abnormal
%   model_name - String for title

if nargin < 3
    model_name = 'SVM';
end

% --- PCA for 2D projection ---
[coeff, score, ~] = pca(X);

% --- Plot ---
figure;
gscatter(score(:,1), score(:,2), Y, 'gr', 'ox', 8);
xlabel('PC 1'); ylabel('PC 2');
legend('Normal', 'Abnormal', 'Location', 'best');
title(sprintf('Feature Separation via PCA (%s)', model_name));
grid on;
end
