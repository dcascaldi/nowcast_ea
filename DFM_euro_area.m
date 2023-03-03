%%% Dynamic factor model (DFM) %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% This script estimates a dynamic factor model (DFM) using a panel of
% monthly and quarterly series.
%
%
% Replication files for:
%
% Back to the Present: Learning about the Euro Area through a Now-casting Model (2021)
% Danilo Cascaldi-Garcia, Thiago Ferreira, Domenico Giannone and Michele Modugno
% International Finance Discussion Papers 1313.
% Board of Governors of the Federal Reserve System (U.S.).
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear; close all;

% load functions
addpath('functions/');

% forecast period
period = '2021q1';
% data to use for the forecast, data to compare against
vintage = '2021-04-20';
vintage_old = '2021-04-15';

country = 'euro_area';       
sample_start  = datenum('1999-01-01','yyyy-mm-dd'); % estimation sample
% these are the series we will forecast
series = 'ea_gdp' ;  % Nowcasting real GDP (gdp) - Euro area
series_ge = 'ge_gdp' ; % Nowcasting real GDP (gdp) - Germany
series_fr = 'fr_gdp' ; % Nowcasting real GDP (gdp) - France
series_it = 'it_gdp' ; % Nowcasting real GDP (gdp) - Italy

%% ------------ Load model specification and dataset ----------------------
% Load model specification structure `Spec`
% Parse `Spec`
Spec = load_spec(['spec_', country, '.xlsx']);
SeriesID = Spec.SeriesID; SeriesName = Spec.SeriesName;
Units = Spec.Units; UnitsTransformed = Spec.UnitsTransformed;

% Load data
datafile = fullfile('data',country,[vintage '.xlsx']);
[X,Time,Z] = load_data(datafile,Spec,sample_start);
summarize(X,Time,Spec,vintage); % summarize data

idxSeries = strcmp(series,SeriesID); t_obs = ~isnan(X(:,idxSeries));
figure('Name',['Data - ' SeriesName{idxSeries}]);

%% -------------------- Plot raw and transformed data ---------------------
subplot(2,1,1); box on;
plot(Time(t_obs),Z(t_obs,idxSeries)); title('raw observed data');
ylabel(Units{idxSeries}); xlim(Time([1 end])); datetick('x','yyyy','keeplimits');

subplot(2,1,2); box on;
plot(Time(t_obs),X(t_obs,idxSeries)); title('transformed data');
ylabel(UnitsTransformed{idxSeries}); xlim(Time([1 end])); datetick('x','yyyy','keeplimits');


%% Run dynamic factor model (DFM) and save estimation output as 'ResDFM'
threshold = 1e-4; % Set to 1e-5 for more robust estimates
%  main 2 lines 
Res = dfmFULLVAR1(X,Spec,threshold);
save('ResDFM','Res','Spec');

%% Projection
n_factors = sum(Res.r); % Number of factors
Projection = Res.C(idxSeries,1:5*n_factors)*Res.Z(:,1:5*n_factors)'*Res.Wx(idxSeries)+Res.Mx(idxSeries);

figure('Name','Projection and GDP data');

plot(Time(t_obs),Projection(t_obs),'k'); hold on;
plot(Time(t_obs), X(t_obs,idxSeries),'b'); box on;
axis tight;
title('Projection and GDP data'); datetick('x','yyyy','keeplimits');
ylabel({Units{idxSeries}, UnitsTransformed{idxSeries}});
legend('Projection','Data'); legend boxoff;

%% -------------- get impact from vintage_old to vintage ------------------
% Load datasets for each vintage
datafile_old = fullfile('data', country, [vintage_old '.xlsx']);
datafile_new = fullfile('data', country, [vintage '.xlsx']);
[X_old,~   ] = load_data(datafile_old,Spec);
[X_new,Time] = load_data(datafile_new,Spec);

% update nowcast for euro area and each country
[y_old,y_new,news_table,revision,impact_revisions] = update_nowcast_out(...
    X_old, X_new, Time, Spec, Res, series, period, vintage_old, vintage);
[y_old_ge,y_new_ge,news_table_ge,revision_ge,impact_revisions_ge] = update_nowcast_out(...
    X_old, X_new, Time, Spec, Res, series_ge, period, vintage_old, vintage);
[y_old_fr,y_new_fr,news_table_fr,revision_fr,impact_revisions_fr] = update_nowcast_out(...
    X_old, X_new, Time, Spec, Res, series_fr, period, vintage_old, vintage);
[y_old_it,y_new_it,news_table_it,revision_it,impact_revisions_it] = update_nowcast_out(...
    X_old, X_new, Time, Spec, Res, series_it, period, vintage_old, vintage);
    
    
%% ----------------------- Save Euro Area agg data ------------------------
releases = news_table.Impact';
save_output = [datenum(vintage,'yyyy-mm-dd'), ...
    datenum(vintage_old,'yyyy-mm-dd'), ...
    y_new,y_old, ...
    impact_revisions, ...
    sum(releases,'omitnan'), ... 
    releases];

save_output_names = [{'date_new'};{'date_old'}; ... 
    {'new_forecast'}; {'old_forecast'}; ...
    {'impact_revision'}; ...
    {'impact_release'}; ...
    news_table.Properties.RowNames];
out_table = table();
for col = 1:size(save_output_names,1)
    out_table{:, save_output_names{col}} = save_output(col);
end
writetable(out_table, ['euro_area_',vintage,'_', period, '.xlsx'])

 