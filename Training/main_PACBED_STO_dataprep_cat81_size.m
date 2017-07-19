clear; %close all;clc
%demo script for PACBED_size CNN data prep
%Weizong Xu, July, 2017
%% get more images (generate signal images)
load('PACBED_STO_14mrad_data_1nm_resolution_0-4mrad_tilt_corr3.mat')
tmp_a=PACBED_data;
tmp_b=name_list;
tmp_c=tilt_list';
load('PACBED_STO_19mrad_data_1nm_resolution_0-4mrad_tilt_corr3.mat')
PACBED_data=[PACBED_data; tmp_a];
name_list=[name_list; tmp_b];
tilt_list=[tilt_list'; tmp_c];
clear tmp_a tmp_b tmp_c
%%
img_num=1;
fpwd='F:\STEM_pattern_data\STO_PACBED_p227_size_14_19mrad';
num_center=50;
index_list=[0];
size_list=240:2:400;
for i=1:length(size_list)
    if ~exist([fpwd,'\','STO_size_',num2str(size_list(i))],'dir')
        mkdir(fpwd,['STO_size_',num2str(size_list(i))])
        disp([fpwd,'\','STO_size_',num2str(size_list(i)),' is created.'])
    end
end
%%
tic
parfor i_size_list=1:length(size_list)
    i_size=size_list(i_size_list);%245:10:395 %for mbfit
    image_sum=zeros(227,227,3);
    num=uint32(0);
    for i_list=6:2:length(list_total) %only 2 nm resolution is good enough
        for i_tilt=1:size(PACBED_data,1)
            PACBED_read=PACBED_data{i_tilt,i_list};
            option=[];
            option.crop_size=i_size;%320
            rng('shuffle')
            option.rng_set=0; % run shuffle gloably to speed up
            option.noise_type='gaussian';%'poisson';
            option.rot_Angle=0;
            option.image_output_size=227;
            option.image_scale=255;
            option.noise_level=0;
            option.signal_level=10;
            option.chk_print=0;
            option.Gaus_blur_size=1;
            option.Avg_size=1;
            option.image_shift=[0,0];
            image_size=size(PACBED_read,1);
            
            i_inten=1.0;
            option.max_intensity_ratio=i_inten;
            disp(['Crop size:',num2str(i_size),' ',num2str(i_list),'nm ',tilt_list{i_tilt},'_TiltCat_',num2str(i_inten), ' #', num2str(num)])
            for i_index=1:length(index_list)
                option.noise_index=index_list(i_index);
                for i_Center=1:num_center
                    img_center=[round(image_size/2), round(image_size/2)];
                    rand_x=image_size;rand_y=image_size;
                    while rand_x*rand_x+rand_y*rand_y>64
                        rand_x=round((rand-0.5)*30);
                        rand_y=round((rand-0.5)*30);
                        option.signal_center(1)=rand_x+img_center(1);
                        option.signal_center(2)=rand_y+img_center(2);
                    end
                    option.distort_signal=1;
                    option.distort_x=(rand()-0.5)*0.02;
                    option.distort_y=(rand()-0.5)*0.02;
                    if i_Center==1 %be sure one training data is in the center
                        option.signal_center(1)=img_center(1);
                        option.signal_center(2)=img_center(2);
                        option.distort_x=0;
                        option.distort_y=0;
                    end
                    i_angle=round(rand()*360);% for i_angle=0:3:357
                    PACBED_read_rot=imrotate(PACBED_read,i_angle,'bicubic','crop');
                    [ image_out, image_raw, ~ ] = PACBED_add_noise_gray( PACBED_read_rot, img_num, option );
                    
                    if i_index>0
                        img_num_eff=img_num;
                    else
                        img_num_eff=1;
                    end
                    
                    for i_img=1:img_num_eff
                        num=num+1;
                        image_sum=image_sum+double(image_out{i_img});
                        filename=[fpwd,'/','STO_size_',num2str(i_size),'/Img_',num2str(num),'.jpg'];
                        imwrite(uint8(image_out{i_img}),filename, 'Quality',94)
                    end
                end
            end
        end
    end
    parsave(['image_sum_size_',num2str(i_size),'.mat'],image_sum,num)
end
toc