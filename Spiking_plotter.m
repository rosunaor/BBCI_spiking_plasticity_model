% Plots for Spiking Simulation Data.
% This script loads data generated by "Spiking_simulator.m" and does various plots. 

%File to load:
load_filename='sample_bbci_Spiking_data.mat';

%Loading data
load(load_filename);
batch_n=p.num_batch;
p.function_path='./functions/'; %folder containing functions necessary for simulation
addpath(p.function_path) %adding folder containing functions


% Some Declarations
%some vars
J=squeeze(Jtraj(:,:,batch_n+1));
RATES=squeeze(RATES_array(:,:,batch_n));
ref_net=1:p.N;

%xcorr from simulated ISI's prep
mean_ISI_counts=mean(ISI_counts(:,:,:,1:batch_n),4);
num_connects=zeros(3,3);
for g_pre=1:3
    for g_post=1:3
        num_connects(g_post,g_pre)=sum(sum(p.J0(p.group_ind{g_post},p.group_ind{g_pre})));
    end
end

%xcorr from Rates prep
maxlags=p.Plast_bin_center(end)/p.dt;
rate_lags=p.Plast_bin_center(1):p.dt:p.Plast_bin_center(end);
Xrates=reshape(RATES_array,[size(RATES_array,1),size(RATES_array,2)*size(RATES_array,3)])+p.net_rate;
ext_xcorr=zeros(3,3,length(rate_lags)); %xcorr of external rates
C_ext_xcorr=zeros(3,3,length(rate_lags)); 

%% Plotting cross-correlations

figure;
for g1=1:3
    for g2=1:3
        %computing xcorr of external rates
        ext_xcorr(g1,g2,:)=xcorr(Xrates(g2,:)/1000,Xrates(g1,:)/1000,maxlags,'none');
        
        %plots
        subplot(3,3,sub2ind([3,3],g1,g2))
        set(gca,'FontSize',13)
        
        %from ISI
        plot(p.Plast_bin_center,squeeze(mean_ISI_counts(g1,g2,:))/num_connects(g1,g2),'k.')
        hold on
        
        %from Rates
        plot(rate_lags,squeeze(ext_xcorr(g1,g2,:))*p.dt/p.num_batch,'r')
        
        plot([0,0],[0,1],'k--')
        hold off
        title([num2str(g2) '-->' num2str(g1)])
        xlabel 'ISI(ms)'
        ylabel 'mean count'
%         axis([p.Plast_bin_center(1) p.Plast_bin_center(end) 0 300])%max(max(max(mean_ISI_counts)))])
    end
end
subplot(3,3,1)
title(['1-->1; RED:drive, BLACK:network'])

%% Sample Raster PLot
%WARNING: simulation only saves the spikes from the very last batch. This
%is what is plotted here, along with the external rates from that same
%batch.

figure;
subplot(2,1,1)
set(gca,'FontSize',13)
hold all
for it=1:3
    plot(linspace(time(batch_n),time(batch_n+1),p.num_batch_steps),RATES(it,:),p.cols{it})
end
hold off
axis([(batch_n-1)*p.T_batch_size,batch_n*p.T_batch_size 0 max(max(max(RATES_array)))+1])
xlabel 'time (s)'
ylabel 'Ext rate (Hz)'
title(['External drive Raster ; BATCH#' num2str(batch_n) '/' num2str(p.num_batch)])

subplot(2,1,2)
set(gca,'FontSize',13)
for n=1:p.N/3
    plot(spikes(n,1:spike_entry(n)-1)/1000+(batch_n-1)*p.T_batch_size,...
        n*ones(spike_entry(n)-1,1),'k.')
    hold on
    if p.stim_switch==1 && n==p.rec_neuron
        plot(spikes(n,1:spike_entry(n)-1)/1000+(batch_n-1)*p.T_batch_size,...
        n*ones(spike_entry(n)-1,1),'ro')
    end
end
for n=p.N/3+1:2*p.N/3
    plot(spikes(n,1:spike_entry(n)-1)/1000+(batch_n-1)*p.T_batch_size,...
        n*ones(spike_entry(n)-1,1),'r.')
    hold on
end
for n=2*p.N/3+1:p.N
    plot(spikes(n,1:spike_entry(n)-1)/1000+(batch_n-1)*p.T_batch_size,...
        n*ones(spike_entry(n)-1,1),'b.')
    hold on
end
hold off
axis([(batch_n-1)*p.T_batch_size,batch_n*p.T_batch_size 0 p.N+1])
xlabel 'time (s)'
ylabel 'neuron #'
if p.stim_switch==1
    title 'Network Raster, Stimulation: ON';
else
    title 'Network Raster, Stimulation: OFF';
end

%%  Synaptic evolution plots

% t_start=0;
% t_stop=p.T_total;

%++++++++++++++++++++
%input 9 colors to plot connections
group_cols=zeros(3,3,3);
group_cols(1,1,:)=[0,0,0]; %black for group 1
group_cols(2,2,:)=[1,0,0]; %red for group 2
group_cols(3,3,:)=[0,0,1]; %blue for group 3
group_cols(2,1,:)=[0.5,0,0];
group_cols(1,2,:)=[0.5,0.5,0];
group_cols(3,1,:)=[0,0,0.5];
group_cols(1,3,:)=[0,0.5,0.5];
group_cols(3,2,:)=[1,0,0.5];
group_cols(2,3,:)=[0.5,0,1];
sim_time=0:p.T_batch_size:p.T_total;
Javr_array=zeros(3,3,size(Jtraj,3));
Jvar_array=zeros(3,3,size(Jtraj,3));
%++++++++++++++++++++

%++++++++++++++++++++
%Computing averages and variances
for g_pre=1:3
    for g_post=1:3
        num_con=sum(sum(p.J0(p.group_ind{g_post},p.group_ind{g_pre})));
        for it=1:size(Jtraj,3)
            Javr_array(g_post,g_pre,it)=sum(sum(squeeze(Jtraj(p.group_ind{g_post},p.group_ind{g_pre},it))))...
                /num_con;
            Jvar_array(g_post,g_pre,it)=sum(sum(squeeze(Jtraj(p.group_ind{g_post},p.group_ind{g_pre},it).^2)))...
                /num_con-Javr_array(g_post,g_pre,it).^2;
        end
    end
end
%++++++++++++++++++++

figure;

subplot(2,1,1)
set(gca,'FontSize',13)
M=10; %number of traces from each group
hold on
for pre=1:3
    for post=1:3
        for pre_n=p.group_ind{pre}(1:M);
            post_group=p.group_ind{post}(1:M);
            post_index=post_group(logical(p.J0(post_group,pre_n)));
            for post_n=post_index
                plot(linspace(0,p.T_total,size(Jtraj,3)),squeeze(Jtraj(post_n,pre_n,:)),'Color',squeeze(group_cols(post,pre,:)),...
                    'LineWidth',0.1,'LineStyle','-');
            end
        end
    end
end
axis([0 p.T_total p.w_min p.w_max])
title(['Sample of ' num2str(M) ' synapses from each group combination'])

subplot(2,1,2)
set(gca,'FontSize',13)
hold on
for pre=1:3
    for post=1:3
%         errorbar(linspace(0,p.T_total,size(Javr_array,3)),squeeze(Javr_array(post,pre,:)),sqrt(squeeze(Jvar_array(post,pre,:))),'Color',squeeze(group_cols(post,pre,:)),...
%            'LineWidth',2,'LineStyle','--');
       plot(linspace(0,p.T_total,size(Javr_array,3)),squeeze(Javr_array(post,pre,:)),'Color',squeeze(group_cols(post,pre,:)),...
           'LineWidth',2,'LineStyle','--');
    end
end
hold off
xlabel 'time (s)'
ylabel 'J_{ij}'
axis([0 p.T_total p.w_min p.w_max])
title(['Group-averaged synaptic strength. Error bars=SD.'])

%% Synaptic Before-and-After plots

%extracting before and after matrices
before_avr=squeeze(Javr_array(:,:,1));
after_avr=squeeze(Javr_array(:,:,end));
before_full=squeeze(Jtraj(:,:,1));
after_full=squeeze(Jtraj(:,:,end));

figure;
%-------
%Before averaged
%-------
subplot(2,3,1)
set(gca,'FontSize',13)
h=bar3(before_avr);
%-- Group Colors
cnt = 0;
for jj = 1:length(h)
    xd = get(h(jj),'xdata');
    yd = get(h(jj),'ydata');
    zd = get(h(jj),'zdata');
    delete(h(jj))    
    idx = [0;find(all(isnan(xd),2))];
    if jj == 1
        S = zeros(length(h)*(length(idx)-1),1);
    end
    for ii = 1:length(idx)-1
        cnt = cnt + 1;
        S(cnt) = surface(xd(idx(ii)+1:idx(ii+1)-1,:),...
                         yd(idx(ii)+1:idx(ii+1)-1,:),...
                         zd(idx(ii)+1:idx(ii+1)-1,:),...
                         'facecolor',group_cols(ii,jj,:));
    end
end
rotate3d
%--
axis([0.5 3.5 0.5 3.5 p.w_min p.w_max])
xlabel 'pre'
ylabel 'post'
title 'Before'
% axis off
view(-30,60)

%-------
%Before averaged
%-------
subplot(2,3,2)
set(gca,'FontSize',13)
h=bar3(after_avr);
%-- Group Colors
cnt = 0;
for jj = 1:length(h)
    xd = get(h(jj),'xdata');
    yd = get(h(jj),'ydata');
    zd = get(h(jj),'zdata');
    delete(h(jj))    
    idx = [0;find(all(isnan(xd),2))];
    if jj == 1
        S = zeros(length(h)*(length(idx)-1),1);
    end
    for ii = 1:length(idx)-1
        cnt = cnt + 1;
        S(cnt) = surface(xd(idx(ii)+1:idx(ii+1)-1,:),...
                         yd(idx(ii)+1:idx(ii+1)-1,:),...
                         zd(idx(ii)+1:idx(ii+1)-1,:),...
                         'facecolor',group_cols(ii,jj,:));
    end
end
rotate3d
%--
axis([0.5 3.5 0.5 3.5 p.w_min p.w_max])
xlabel 'pre'
ylabel 'post'
title 'After'
% axis off
view(-30,60)

%Before Full
subplot(2,3,4)
set(gca,'FontSize',13)
pcolor(flipud(before_full))
caxis([p.w_min,p.w_max])
xlabel 'pre'
ylabel 'post'
title 'Before (full)'

%After full
subplot(2,3,5)
set(gca,'FontSize',13)
pcolor(flipud(after_full))
caxis([p.w_min,p.w_max])
xlabel 'pre'
ylabel 'post'
title 'After (full)'

%-------
%NORMALIZED difference
%-------
subplot(2,3,[3,6])
A=(after_avr-before_avr)/0.02; %normalized diff
set(gca,'FontSize',8)
tix=cell(9,1);
alpha={'a','b','c'};
hold all
counter=1;
for pre=1:3
    for post=1:3
        bar(counter,A(post,pre),'FaceColor',group_cols(post,pre,:));
        tix{counter}=[];
        counter=counter+1;
    end
end
hold off
set(gca,'XTickLabel',tix,'FontSize',13)
axis([0 10 -0.2 1])
title('Normalized synaptic change')


