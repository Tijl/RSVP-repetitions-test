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

%%
f=figure(1);clf;
f.Position(3:4) = [600 600];
n = numel(unique(res_all_5hz.sa.subjectnr));
res_mu = cosmo_fx(res_all_5hz,@(x) mean(x,1),{'blocknr'});
res_mu.samples = res_mu.samples-1/200;
res_se = cosmo_fx(res_all_5hz,@(x) std(x,[],1),{'blocknr'});
res_se.samples = res_se.samples./sqrt(n);

a = subplot(2,2,1);
tv = res_mu.a.fdim.values{1};
imagesc(tv,1:numel(res_mu.sa.blocknr),res_mu.samples,[0,prctile(res_mu.samples(:),99)]);
colormap(inferno)
a.YTick = 1:2:numel(res_mu.sa.blocknr);
a.YTickLabel = res_mu.sa.blocknr(a.YTick);
a.YDir = 'normal';
xlabel('time (ms)')
ylabel('repetitions')
title('A image decoding means','Units','normalized','Position',[-.2 1.1],'HorizontalAlignment','left')

a = subplot(2,2,2);
tv = res_mu.a.fdim.values{1};
pval = 1-tcdf(res_mu.samples./res_se.samples,n-1);
for i=1:size(pval,1)
    pval(i,:) = pval(i,:) < fdr(pval(i,:),.05);
end
imagesc(tv,1:numel(res_mu.sa.blocknr),pval);
colormap(inferno)
a.YTick = 1:2:numel(res_mu.sa.blocknr);
a.YTickLabel = res_mu.sa.blocknr(a.YTick);
a.YDir = 'normal';
xlabel('time (ms)')
ylabel('repetitions')
title('B statistically reliable (p<.05; fdr-corrected)','Units','normalized','Position',[-.2 1.1],'HorizontalAlignment','left')

a = subplot(2,2,3);
[~,tidx] = max(mean(res_mu.samples));
errorbar(res_mu.sa.blocknr,res_mu.samples(:,tidx),norminv(.975)*res_se.samples(:,tidx),'k');hold on
plot(tv,0*tv,'k--')
a.XTick = res_mu.sa.blocknr(1:2:end);
a.XLim = [2 41];
xlabel('repetitions')
ylabel('accuracy-chance')
title('C decoding at peak (132ms)','Units','normalized','Position',[-.2 1.1],'HorizontalAlignment','left')

a = subplot(2,2,4);
R = corr(res_mu.samples');
plot(res_mu.sa.blocknr,R(end,:),'k','LineWidth',2)
a.XTick = res_mu.sa.blocknr(1:2:end);
a.XLim = [2 41];
a.YLim = [0 1];
xlabel('repetitions')
ylabel('correlation (\rho)')
title('D correlation with full dataset','Units','normalized','Position',[-.2 1.1],'HorizontalAlignment','left')

for i=1:4
    a = subplot(2,2,i)
    a.FontSize=12;
end

%%
fn = 'figures/figure_summary';
tn = tempname;
print(gcf,'-dpng','-r500',tn)
im=imread([tn '.png']);
[i,j]=find(mean(im,3)<255);margin=2;
imwrite(im(min(i-margin):max(i+margin),min(j-margin):max(j+margin),:),[fn '.png'],'png');

