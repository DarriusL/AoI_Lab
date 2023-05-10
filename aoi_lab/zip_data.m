function zip_data
    disp("正在压缩仿真数据...");
    mkdir lab_data
    copyfile data lab_data

    zip lab_data lab_data
    rmdir lab_data s
    disp("仿真数据压缩成功，存储在当前目录下")
    disp("*下次运行环境时将自动清除");
    toc
end