function zip_lab
    mkdir AoI_Lab
    mkdir AoI_Lab\data
    copyfile aoi_lab AoI_Lab
    copyfile config AoI_Lab
    copyfile job AoI_Lab
    copyfile lib AoI_Lab
    copyfile model AoI_Lab
    copyfile test AoI_Lab
    copyfile run_lab.m AoI_Lab
    copyfile SetCurrentFile.m AoI_Lab
    
    zip AoI_Lab AoI_Lab
    rmdir AoI_Lab
end