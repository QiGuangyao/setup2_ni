function vid_ts = get_video_times_from_saveable_data(saveable_data)

vid_ts = datetime( saveable_data.video_data.vs1.Value.vid_time );

end