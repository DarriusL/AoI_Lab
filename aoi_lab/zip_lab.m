function zip_lab
    disp("正在压缩环境...");
    mkdir AoI_Lab_
    mkdir AoI_Lab_\data
    copyfile aoi_lab AoI_Lab_\aoi_lab
    copyfile config AoI_Lab_\config
    copyfile job AoI_Lab_\job
    copyfile lib AoI_Lab_\lib
    copyfile model AoI_Lab_\model
    copyfile test AoI_Lab_\test
    copyfile run_lab.m AoI_Lab_
    copyfile SetCurrentFile.m AoI_Lab_
    
    zip AoI_Lab_ AoI_Lab_
    rmdir AoI_Lab_ s
    disp("环境压缩成功，存储在当前目录下")
    disp("*下次运行环境时将自动清除");
    toc
end