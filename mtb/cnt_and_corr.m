clc
clear
x=0:pi/20:pi;
ratio_list=((1+0.886*cos(x))/2)./((1-0.886*cos(x))/2);
ratio_list(1)=1000;
ratio_list(end)=0.00001;

clear x;

for phase_i=1:20
    
    effective_time_list=zeros(1,20);
    
    for fi=1:10 %355s one loop.
        fclose all;
        delete('Chlist.bin');
        delete('timelist.bin');
        
        tic
        wi = 1;
        
        saveDatapath='.\data';
        filelist=dir('.\data\*example.ttbin');
        % filelist(1).name
        saveFilename='20221115145930example';
        filepath = fullfile(saveDatapath, filelist(fi).name);
        file_reader = TTFileReader(filepath);
        
        
        ms=10^9;
        us=10^6;
        s=10^12;
        count_bin=100*ms; %count rate bin
        count_range=1200*s;%count rate range
        % count_range=100*s;
        counts5=zeros(1,ceil(count_range/count_bin));
        counts7=zeros(1,ceil(count_range/count_bin));
        count_x=0.1*(1:length(counts5));
        
        
        blocksize=10000000;
        countsnum=0;
        totaltime=0;
        left_ti=1;
        right_ti=1;
        count_list=[];
        
        fid1=fopen('Chlist.bin','a');
        fid2=fopen('timelist.bin','a');
        
        %% export data of insteret based on counting ratio.
        while file_reader.hasData()
            data = file_reader.getData(blocksize);
            ch = (data.getChannels());
            times = double(data.getTimestamps());
            countsnum=countsnum+length(ch);
            left_ti=1;
            right_ti=1;
            
            if wi==1
                t0=times(1);
            else
                ch=[chend ch];
                times=[timeend times];
            end
            
            cnt_int=floor((times(end)-t0)/(count_bin)); %每块数据的整数bin
            
            for i=1:length(ch)-1
                dt1=times(i)-t0;
                dt2=times(i+1)-t0;
                if floor(dt1/count_bin)==floor(dt2/count_bin)
                    ti=floor(dt1/count_bin)+1;
                    if ch(i)==5
                        counts5(ti)=counts5(ti)+1;
                    else
                        counts7(ti)=counts7(ti)+1;
                    end
                else
                    right_ti=i;
                    % Export data of interest.
                    if  (counts5(ti)/counts7(ti))<=ratio_list(phase_i) && (counts5(ti)/counts7(ti))>=ratio_list(phase_i+1)%Pi/2\pm Pi/20 and 3Pi/2\pm Pi/20    (counts5(ti)/counts7(ti))>=0.729 && (counts5(ti)/counts7(ti))<=1.371
                        count_list=[count_list counts5(ti) counts7(ti)];
                        fwrite(fid1, ch(left_ti:right_ti),'int8');
                        fwrite(fid2, times(left_ti:right_ti), 'int64');
                        totaltime=totaltime+1;
                    end
                    left_ti=i+1;
                    %Extract timestamps of the end.
                    if ti==cnt_int
                        %                 disp(ti);
                        chend=ch(i+1:end);
                        timeend=times(i+1:end);
                        break;
                    end
                    
                end
            end
            
            %  计算count rate
            %     for i=1:length(ch)
            %         ti=floor((times(i)-t0)/count_bin)+1;
            %
            %         if ch(i)==5
            %             counts5(ti)=counts5(ti)+1;
            %         else
            %             counts7(ti)=counts7(ti)+1;
            %         end
            %     end
            
            disp(['file-',num2str(fi),'  ',num2str(100*wi/444),' %.'])
%             if wi==60
%                 break;
%             end
            wi = wi+1;
            
        end
        fclose(fid1);
        fclose(fid2);
        disp(['Effective total time is: ', num2str(totaltime/10),' s.'])
        effective_time_list(fi)=totaltime/10;
        toc
        
        % fig1=plot(count_x,counts5,count_x,counts7);
        % xlabel('Time (s)');
        % ylabel('Counts per bin');
        % savefig('figure1.fig');
        
        %% correlation calculation
        
        corrbin = 10; % ps
        corr_counts = 2000;
        % range of time differences
        corr_range = corrbin*corr_counts/2;
        bincounts=zeros(1,2*corr_range/corrbin);
        
        k = 1;
        wi=1;
        fid1=fopen('Chlist.bin','r');
        fid2=fopen('timelist.bin','r');
        
        while ~feof(fid1)
            ch = fread(fid1, blocksize, 'int8');
            times = fread(fid2, blocksize, 'int64');
            
            if wi~=1
                ch=[chend ch];
                times=[timeend times];
            end
            a = 100;
            if ~feof(fid1)
                a = 0;
            end
            timeDifference=[];
            for i=1:length(ch)-a
                for j=i+1:length(ch)
                    if  times(j)-times(i) > corr_range
                        break;
                    end
                    if ch(i)~=ch(j)
                        dt = times(j)-times(i);
                        if ch(j) == 7
                            timeDifference(k) = -dt;
                            k = k+1;
                        else
                            timeDifference(k) = dt;
                            k = k+1;
                        end
                    end
                end
            end
            
            if ~isempty(timeDifference)
                bincounts=histcounts(timeDifference, -corr_range:10:corr_range)+bincounts;
                clear timeDifference;
            end
            
            k=1;
            
            chend=ch(i+1:end);
            timeend=times(i+1:end);
            %             if wi==2
            %                 break;
            %             end
            disp(['newfile-',num2str(fi),'  ',num2str(100*wi/(totaltime/13)),' %.'])
            wi = wi+1;
        end
        fclose(fid1);
        fclose(fid2);
        
        fid=fopen(['phase', num2str(phase_i),'-bincounts-' num2str(fi) '.bin'], 'w');
        fwrite(fid, bincounts, 'int32');
        fclose(fid);
        
        toc
    end
    
    fid=fopen(['phase', num2str(phase_i),'_effectvie_time.txt'],'w');
    fprintf(fid,'file \t effective time\n');
    fprintf(fid,'%d\t%4.1f \n',[1:1:20; effective_time_list]);
    fclose(fid);
    
end