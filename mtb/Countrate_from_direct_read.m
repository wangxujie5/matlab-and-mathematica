clc;clear;
for fi=1:1
    tic;
    wi=1;
    datapath='.\data';
    filelist=dir('.\data\*example.ttbin');
%     saveFilename='20221115145930example';
    filepath = fullfile(datapath, filelist(fi).name);
    file_reader = TTFileReader(filepath);
    
    ms=10^9;
    us=10^6;
    s=10^12;
    count_bin=100*ms; %count rate bin
    count_range=1210*s;%count rate range
%     count_range=100*s;
    counts5=zeros(1,ceil(count_range/count_bin));
    counts7=zeros(1,ceil(count_range/count_bin));
    counts14=zeros(1,ceil(count_range/count_bin));

    blocksize=10000000;
    
    while file_reader.hasData()
        data=file_reader.getData(blocksize);
        ch = (data.getChannels());
        times = double(data.getTimestamps());
        
        if wi==1
            t0=times(1);            
        end
        
        for i=1:length(ch)
            ti=floor((times(i)-t0)/count_bin)+1;
            
            if ch(i)==5
                counts5(ti)=counts5(ti)+1;
            elseif ch(i)==7
                counts7(ti)=counts7(ti)+1;
            else
                counts14(ti)=counts14(ti)+1;
            end
        end
        disp(['file-',num2str(fi),'  ',num2str(100*wi/222),' %.'])
%             if wi==1
%                 break;
%             end
        wi = wi+1;
        
    end
    toc
    
    counts5=counts5(counts5~=0);
    counts7=counts7(counts7~=0);
    counts14=counts14(counts14~=0);
    fid1=fopen([num2str(fi),'_CountRate_5.txt'],'w');
    fprintf(fid1,'%d \n',counts5);
    fclose(fid1);
    fid2=fopen([num2str(fi),'_CountRate_7.txt'],'w');
    fprintf(fid2,'%d \n',counts7);
    fclose(fid2);
    count_x=0.1*(1:length(counts5));
    plot(count_x,counts5,count_x,counts7,count_x,counts14);
    saveas(gcf, ['CountRate-',num2str(fi),'.jpg']);


end

