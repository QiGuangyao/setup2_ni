function collM2Matr = collM2Trials(block_type, name_of_m1,name_of_m2)
  collM2Matr = [];
  dataPath = 'D:\tempData\coordination\data';
  files = dir(fullfile(dataPath));
  files(1:2) = [];
  dateName = datestr(datetime('today'));

  seleFile = [];
  for i =1:length(files)
    if strcmp(files(i).name(1:11),dateName) && strcmp(files(i).name(22:end),['block_type_',num2str(block_type)])
      i
      files(i).name(1:11)
      seleFile = [seleFile,i];
    end
  end
  seleFiles = files(seleFile);
  dateVector = datevec(dateName);
  numericDate = dateVector(1)*10000 + dateVector(2)*100 + dateVector(3);
  for b =1:length(seleFiles)
    cd([files(seleFile(b)).folder,'\',files(seleFile(b)).name]);
    load([files(seleFile(b)).folder,'\',files(seleFile(b)).name,'\','task_data.mat']);
    if strcmp(saveable_data.params.m1, name_of_m1) && strcmp(saveable_data.params.m2, name_of_m2)
      collM2Matr = [collM2Matr saveable_data.trials(1, length(saveable_data.trials)).m1_m2_beha_sum];
    end
  end
end