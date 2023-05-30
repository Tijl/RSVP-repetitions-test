%% 
fns = dir('results/sub-*_run01_decoding.mat')
res_cell = {};
for f=1:numel(fns)
    load(sprintf('results/%s',fns(f).name));
    res_cell{f} = res;
end
res_all_5hz = cosmo_stack(res_cell);

%%
addpath('~/CoSMoMVPA/mvpa/')
addpath('../CommonFunctions/matplotlib/')
addpath('../CommonFunctions/BayesFactors/')

%% calc BF
cc=clock();mm='';
splits = cosmo_split(res_all_5hz,'blocknr');
res_cell = {};
for b=1:numel(splits)
    s = cosmo_fx(splits{b},@mean);
    s.samples(:) = bayesfactor_R_wrapper(100*splits{b}.samples'-.5,'args','mu=0,rscale="medium",nullInterval=c(-Inf,0.5)','returnindex',2);
    res_cell{b} = s;
    mm=cosmo_show_progress(cc,b/numel(splits),'',mm);
end
res_bf = cosmo_stack(res_cell);

%%
f=figure(1);clf;
f.Position(3:4) = [800 800];
n = numel(unique(res_all_5hz.sa.subjectnr));
res_mu = cosmo_fx(res_all_5hz,@(x) mean(x,1),{'blocknr'});
res_mu.samples = 100*(res_mu.samples);
res_se = cosmo_fx(res_all_5hz,@(x) std(x,[],1),{'blocknr'});
res_se.samples = 100*res_se.samples./sqrt(n);

a = subplot(3,2,1);
tv = res_mu.a.fdim.values{1};
imagesc(tv,1:numel(res_mu.sa.blocknr),res_mu.samples,[.5,1.1]);
colormap(a,inferno)
c=colorbar;
a.YTick = 2:4:numel(res_mu.sa.blocknr);
a.YTickLabel = res_mu.sa.blocknr(a.YTick);
a.YDir = 'normal';
xlabel('time (ms)')
ylabel('repetitions')
title('A  Image decoding means','Units','normalized','Position',[-.2 1.1],'HorizontalAlignment','left')

a = subplot(3,2,3);
tv = res_mu.a.fdim.values{1};
pval = 1-tcdf((res_mu.samples-.5)./res_se.samples,n-1);
for i=1:size(pval,1)
    pval(i,:) = pval(i,:) < fdr(pval(i,:),.05);
end
imagesc(tv,1:numel(res_mu.sa.blocknr),pval,[-.5 1.5]);
colormap(a,flipud(twilight(2)))
c=colorbar;c.Ticks=[0 1];c.TickLabels={'p≥0.05','p<0.05'}
a.YTick = 2:4:numel(res_mu.sa.blocknr);
a.YTickLabel = res_mu.sa.blocknr(a.YTick);
a.YDir = 'normal';
xlabel('time (ms)')
ylabel('repetitions')
title('B  Statistically reliable (p<.05; fdr-corrected)','Units','normalized','Position',[-.2 1.1],'HorizontalAlignment','left')

a = subplot(3,2,5);
tv = res_bf.a.fdim.values{1};
imagesc(tv,1:numel(res_mu.sa.blocknr),fix(log10(res_bf.samples)),[-4.5 4.5]);
colormap(a,flipud(circshift(twilight(9),fix(9/2),1)))
a.YTick = 2:4:numel(res_mu.sa.blocknr);
a.YTickLabel = res_mu.sa.blocknr(a.YTick);
c=colorbar;
c.Ticks=-4:4;
for i=1:numel(c.Ticks)
    if c.Ticks(i)<0
        c.TickLabels{i} = sprintf('≤%g',10.^c.Ticks(i));
    elseif c.Ticks(i)>0
        c.TickLabels{i} = sprintf('≥%.0f',10.^c.Ticks(i));
    else
        c.TickLabels{i} = 'BF';
    end
end
a.YDir = 'normal';
xlabel('time (ms)')
ylabel('repetitions')
title('C  Bayes Factors','Units','normalized','Position',[-.2 1.1],'HorizontalAlignment','left')

a = subplot(3,2,2);
res_mu_select = cosmo_slice(res_mu,fliplr(2:6:size(res_mu.samples,1)));
a.ColorOrder = viridis(size(res_mu_select.samples,1));hold on
plot(tv,res_mu_select.samples,'LineWidth',1)
plot(tv,.5+0*tv,'k--')
a.XLim = minmax(tv);
legend(strsplit(sprintf('%i,',res_mu_select.sa.blocknr),','))
xlabel('time (ms)')
ylabel('accuracy')
title('D  Mean decoding over time','Units','normalized','Position',[-.2 1.1],'HorizontalAlignment','left')

a = subplot(3,2,4);
[~,tidx] = max(mean(res_mu.samples));
errorbar(res_mu.sa.blocknr,res_mu.samples(:,tidx),norminv(.975)*res_se.samples(:,tidx),'k');hold on
plot(tv,.5+0*tv,'k--')
a.XTick = res_mu.sa.blocknr(2:4:end);
a.XLim = [2 41];
xlabel('repetitions')
ylabel('accuracy')
title(sprintf('E  Decoding at peak (%ims)',tv(tidx)),'Units','normalized','Position',[-.2 1.1],'HorizontalAlignment','left')

a = subplot(3,2,6);
R = corr(res_mu.samples');
plot(res_mu.sa.blocknr,R(end,:),'k','LineWidth',2)
a.XTick = res_mu.sa.blocknr(2:4:end);
a.XLim = [2 41];
a.YLim = [0 1];
xlabel('repetitions')
ylabel('correlation (\rho)')
title('F  Correlation with full dataset','Units','normalized','Position',[-.2 1.1],'HorizontalAlignment','left')

set(f.Children,'FontSize',12)

%%
fn = 'figures/figure_summary';
tn = tempname;
print(gcf,'-dpng','-r500',tn)
im=imread([tn '.png']);
[i,j]=find(mean(im,3)<255);margin=2;
imwrite(im(min(i-margin):max(i+margin),min(j-margin):max(j+margin),:),[fn '.png'],'png');

