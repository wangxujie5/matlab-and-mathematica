clc;clear;
% %% write matrix to txt
% fileID=fopen('correlationpm2GHz.txt','w');
% for i=1:length(bin_x)
%     fprintf(fileID, '%d %d\n',bin_x(i),corr(i));
% end
% fclose(fileID);

%% read matrix from txt
data=readmatrix("correlation0GHz.txt");
x=data(:,1)./10^6;
y=data(:,2)./max(data(:,2));
data=readmatrix("correlationpm2GHz.txt");
x1=data(:,1)./10^6;
y1=data(:,2)./max(data(:,2));
plot(x,y,x1,y1)
xlabel('tau (us)');
ylabel('Normalized coincidence');
legend('0 GHz','±2 GHz');

figure(2);
condition1=x>=0;
% ylim([0,1.2*10^5])
plot(x(condition1),y(condition1),x1(condition1),y1(condition1));
new_x=x(condition1);
new_y=y(condition1);

xlabel('tau (us)');
ylabel('Normalized coincidence')
ft=fittype('a*exp(-t/tau)+(1-a)','independent','t','coefficients',{'a','tau'});
myfit=fit(new_x,new_y,ft,"StartPoint",[0.3, 100]);
myfit2=fit(x1(condition1),y1(condition1),ft,"StartPoint",[0.4, 100]);
y_fitvalue=myfit(new_x);
y2_fitvalue=myfit2(new_x);
hold on;
plot(new_x,y_fitvalue,'g:','LineWidth',3);
plot(new_x,y2_fitvalue,'m--','LineWidth',3);
hold off;
legend('0 GHz','±2 GHz','fit1','fit2');
xlim([0, 600]);

