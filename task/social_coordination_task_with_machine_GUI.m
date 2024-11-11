function social_coordination_task_with_machine_GUI
    % Create the main figure window
    f = figure('Position', [300, 50, 700, 650], 'Name', 'Social Coordination Task Parameters');
    
    % Title
    uicontrol('Style', 'text', 'Position', [200, 600, 200, 30], 'String', 'Task Parameters', 'FontSize', 14, 'FontWeight', 'bold');
    
    % Define layout parameters
    col1_x = 50; % X position for the first column
    col2_x = 320; % X position for the second column
    label_width = 150; % Width of label text
    input_width = 100; % Width of input fields
    height = 20; % Height of text and input fields
    padding = 10; % Padding between fields
    y_start = 560; % Starting Y position for fields
    
    % Column 1 - Parameter Labels and Inputs
    uicontrol('Style', 'text', 'Position', [col1_x, y_start, label_width, height], 'String', 'Use Eye ROI', 'HorizontalAlignment', 'left');
    useEyeROI_checkbox = uicontrol('Style', 'checkbox', 'Position', [col1_x + label_width, y_start, input_width, height], 'Value', 0);

    uicontrol('Style', 'text', 'Position', [col1_x, y_start - (height + padding), label_width, height], 'String', 'Eye ROI Padding X (pix):', 'HorizontalAlignment', 'left');
    eye_roi_padding_x_edit = uicontrol('Style', 'edit', 'Position', [col1_x + label_width, y_start - (height + padding), input_width, height], 'String', '50');

    uicontrol('Style', 'text', 'Position', [col1_x, y_start - 2 * (height + padding), label_width, height], 'String', 'Eye ROI Padding Y (pix):', 'HorizontalAlignment', 'left');
    eye_roi_padding_y_edit = uicontrol('Style', 'edit', 'Position', [col1_x + label_width, y_start - 2 * (height + padding), input_width, height], 'String', '50');

    uicontrol('Style', 'text', 'Position', [col1_x, y_start - 3 * (height + padding), label_width, height], 'String', 'Face ROI Padding X (pix):', 'HorizontalAlignment', 'left');
    face_roi_padding_x_edit = uicontrol('Style', 'edit', 'Position', [col1_x + label_width, y_start - 3 * (height + padding), input_width, height], 'String', '50');

    uicontrol('Style', 'text', 'Position', [col1_x, y_start - 4 * (height + padding), label_width, height], 'String', 'Face ROI Padding Y (pix):', 'HorizontalAlignment', 'left');
    face_roi_padding_y_edit = uicontrol('Style', 'edit', 'Position', [col1_x + label_width, y_start - 4 * (height + padding), input_width, height], 'String', '50');

    uicontrol('Style', 'text', 'Position', [col1_x, y_start - 5 * (height + padding), label_width, height], 'String', 'State duration (s):', 'HorizontalAlignment', 'left');
    initial_fixation_state_duration_edit = uicontrol('Style', 'edit', 'Position', [col1_x + label_width, y_start - 5 * (height + padding), input_width, height], 'String', '0.1');

    uicontrol('Style', 'text', 'Position', [col1_x, y_start - 6 * (height + padding), label_width, height], 'String', 'Fixation Duration M1 (s):', 'HorizontalAlignment', 'left');
    fixation_duration_m1_edit = uicontrol('Style', 'edit', 'Position', [col1_x + label_width, y_start - 6 * (height + padding), input_width, height], 'String', '0.1');

    uicontrol('Style', 'text', 'Position', [col1_x, y_start - 7 * (height + padding), label_width, height], 'String', 'Fixation Duration M2 (s):', 'HorizontalAlignment', 'left');
    fixation_duration_m2_edit = uicontrol('Style', 'edit', 'Position', [col1_x + label_width, y_start - 7 * (height + padding), input_width, height], 'String', '0.1');

    uicontrol('Style', 'text', 'Position', [col1_x, y_start - 8 * (height + padding), label_width, height], 'String', 'ITI Duration (s):', 'HorizontalAlignment', 'left');
    iti_duration_edit = uicontrol('Style', 'edit', 'Position', [col1_x + label_width, y_start - 8 * (height + padding), input_width, height], 'String', '1');

    uicontrol('Style', 'text', 'Position', [col1_x, y_start - 9 * (height + padding), label_width, height], 'String', 'Initial Reward M1 (s):', 'HorizontalAlignment', 'left');
    initial_reward_m1_edit = uicontrol('Style', 'edit', 'Position', [col1_x + label_width, y_start - 9 * (height + padding), input_width, height], 'String', '0.05');

    uicontrol('Style', 'text', 'Position', [col1_x, y_start - 10 * (height + padding), label_width, height], 'String', 'Initial Reward M2 (s):', 'HorizontalAlignment', 'left');
    initial_reward_m2_edit = uicontrol('Style', 'edit', 'Position', [col1_x + label_width, y_start - 10 * (height + padding), input_width, height], 'String', '0.05');

    uicontrol('Style', 'text', 'Position', [col1_x, y_start - 11 * (height + padding), label_width, height], 'String', 'Initial Reward M1 & M2 (s):', 'HorizontalAlignment', 'left');
    init_reward_m1_m2_edit = uicontrol('Style', 'edit', 'Position', [col1_x + label_width, y_start - 11 * (height + padding), input_width, height], 'String', '0.2');

    uicontrol('Style', 'text', 'Position', [col1_x, y_start - 12 * (height + padding), label_width, height], 'String', 'Error Duration (s):', 'HorizontalAlignment', 'left');
    error_duration_edit = uicontrol('Style', 'edit', 'Position', [col1_x + label_width, y_start - 12 * (height + padding), input_width, height], 'String', '0.5');
    
    % Column 2 - Parameter Labels and Inputs
    uicontrol('Style', 'text', 'Position', [col2_x, y_start, label_width, height], 'String', 'Name of M1:', 'HorizontalAlignment', 'left');
    name_of_m1_edit = uicontrol('Style', 'edit', 'Position', [col2_x + label_width, y_start, input_width, height], 'String', 'M1_lynch');

    uicontrol('Style', 'text', 'Position', [col2_x, y_start - (height + padding), label_width, height], 'String', 'Name of M2:', 'HorizontalAlignment', 'left');
    name_of_m2_edit = uicontrol('Style', 'edit', 'Position', [col2_x + label_width, y_start - (height + padding), input_width, height], 'String', 'M2_ephron');

    uicontrol('Style', 'text', 'Position', [col2_x, y_start - 2 * (height + padding), label_width, height], 'String', 'Fix Cross Visu Angl (deg):', 'HorizontalAlignment', 'left');
    fix_cross_visu_angl_edit = uicontrol('Style', 'edit', 'Position', [col2_x + label_width, y_start - 2 * (height + padding), input_width, height], 'String', '6');

    uicontrol('Style', 'text', 'Position', [col2_x, y_start - 3 * (height + padding), label_width, height], 'String', 'Total Distance M1 (mm):', 'HorizontalAlignment', 'left');
    totdist_m1_edit = uicontrol('Style', 'edit', 'Position', [col2_x + label_width, y_start - 3 * (height + padding), input_width, height], 'String', '450');

    uicontrol('Style', 'text', 'Position', [col2_x, y_start - 4 * (height + padding), label_width, height], 'String', 'Total Distance M2 (mm):', 'HorizontalAlignment', 'left');
    totdist_m2_edit = uicontrol('Style', 'edit', 'Position', [col2_x + label_width, y_start - 4 * (height + padding), input_width, height], 'String', '515');

    uicontrol('Style', 'text', 'Position', [col2_x, y_start - 5 * (height + padding), label_width, height], 'String', 'Screen Height Left (cm):', 'HorizontalAlignment', 'left');
    screen_height_left_edit = uicontrol('Style', 'edit', 'Position', [col2_x + label_width, y_start - 5 * (height + padding), input_width, height], 'String', '8.5');

    uicontrol('Style', 'text', 'Position', [col2_x, y_start - 6 * (height + padding), label_width, height], 'String', 'Padding Angle (deg):', 'HorizontalAlignment', 'left');
    padding_angl_edit = uicontrol('Style', 'edit', 'Position', [col2_x + label_width, y_start - 6 * (height + padding), input_width, height], 'String', '2');

    uicontrol('Style', 'text', 'Position', [col2_x, y_start - 7 * (height + padding), label_width, height], 'String', 'Enable Remap', 'HorizontalAlignment', 'left');
    enable_remap_checkbox = uicontrol('Style', 'checkbox', 'Position', [col2_x + label_width, y_start - 7 * (height + padding), input_width, height], 'Value', 1);

    uicontrol('Style', 'text', 'Position', [col2_x, y_start - 8 * (height + padding), label_width, height], 'String', 'Save Data', 'HorizontalAlignment', 'left');
    save_data_checkbox = uicontrol('Style', 'checkbox', 'Position', [col2_x + label_width, y_start - 8 * (height + padding), input_width, height], 'Value', 1);

    uicontrol('Style', 'text', 'Position', [col2_x, y_start - 9 * (height + padding), label_width, height], 'String', 'Full Screens', 'HorizontalAlignment', 'left');
    full_screens_checkbox = uicontrol('Style', 'checkbox', 'Position', [col2_x + label_width, y_start - 9 * (height + padding), input_width, height], 'Value', 1);

    uicontrol('Style', 'text', 'Position', [col2_x, y_start - 10 * (height + padding), label_width, height], 'String', 'Max Number of Trials:', 'HorizontalAlignment', 'left');
    max_num_trials_edit = uicontrol('Style', 'edit', 'Position', [col2_x + label_width, y_start - 10 * (height + padding), input_width, height], 'String', '30');

    
    
%     uicontrol('Style', 'text', 'Position', [col2_x, y_start - 11 * (height + padding), label_width, height], 'String', 'Play feedback sound:', 'HorizontalAlignment', 'left');
%     play_feedback_sound_edit = uicontrol('Style', 'edit', 'Position', [col2_x + label_width, y_start - 11 * (height + padding), input_width, height], 'String', 1);


    uicontrol('Style', 'text', 'Position', [col2_x, y_start - 11 * (height + padding), label_width, height], 'String', 'Play feedback sound: ', 'HorizontalAlignment', 'left');
    play_feedback_sound_edit = uicontrol('Style', 'checkbox', 'Position', [col2_x + label_width, y_start - 11 * (height + padding), input_width, height], 'Value', 1);

    uicontrol('Style', 'text', 'Position', [col2_x, y_start - 12 * (height + padding), label_width, height], 'String', 'Saved file directory:', 'HorizontalAlignment', 'left');
    proj_p_edit = uicontrol('Style', 'edit', 'Position', [col2_x + label_width, y_start - 12 * (height + padding), input_width*2, height], 'String', 'D:\tempData\coordination');

    % Start Button
    uicontrol('Style', 'pushbutton', 'Position', [250, 20, 100, 40], 'String', 'Start Task', ...
        'Callback', @startTaskCallback);
    
    function startTaskCallback(~, ~)
        % Retrieve parameter values from GUI
        useEyeROI = get(useEyeROI_checkbox, 'Value');
        m2_eye_roi_padding_x = str2double(get(eye_roi_padding_x_edit, 'String'));
        m2_eye_roi_padding_y = str2double(get(eye_roi_padding_y_edit, 'String'));
        m2_face_roi_padding_x = str2double(get(face_roi_padding_x_edit, 'String'));
        m2_face_roi_padding_y = str2double(get(face_roi_padding_y_edit, 'String'));
        initial_fixation_state_duration = str2double(get(initial_fixation_state_duration_edit, 'String'));
        initial_fixation_duration_m1 = str2double(get(fixation_duration_m1_edit, 'String'));
        initial_fixation_duration_m2 = str2double(get(fixation_duration_m2_edit, 'String'));
        iti_duration = str2double(get(iti_duration_edit, 'String'));
        initial_reward_m1 = str2double(get(initial_reward_m1_edit, 'String'));
        initial_reward_m2 = str2double(get(initial_reward_m2_edit, 'String'));
        init_reward_m1_m2 = str2double(get(init_reward_m1_m2_edit, 'String'));
        error_duration = str2double(get(error_duration_edit, 'String'));
        name_of_m1 = get(name_of_m1_edit, 'String');
        name_of_m2 = get(name_of_m2_edit, 'String');
        fix_cross_visu_angl = str2double(get(fix_cross_visu_angl_edit, 'String'));
        totdist_m1 = str2double(get(totdist_m1_edit, 'String'));
        totdist_m2 = str2double(get(totdist_m2_edit, 'String'));
        screen_height_left = str2double(get(screen_height_left_edit, 'String'));
        padding_angl = str2double(get(padding_angl_edit, 'String'));
        enable_remap = get(enable_remap_checkbox, 'Value');
        save_data = get(save_data_checkbox, 'Value');
        full_screens = get(full_screens_checkbox, 'Value');
        max_num_trials = str2double(get(max_num_trials_edit, 'String'));
        play_feedback_sound =  get(play_feedback_sound_edit, 'Value');  

        proj_p =  get(proj_p_edit, 'String');



        % Display the parameter values for debugging
        disp('Starting Task with Parameters:');
        disp(['Use Eye ROI: ', num2str(useEyeROI)]);
        disp(['Eye ROI Padding X: ', num2str(m2_eye_roi_padding_x)]);
        disp(['Eye ROI Padding Y: ', num2str(m2_eye_roi_padding_y)]);
        disp(['Face ROI Padding X: ', num2str(m2_face_roi_padding_x)]);
        disp(['Face ROI Padding Y: ', num2str(m2_face_roi_padding_y)]);
        disp(['State duration: ', num2str(initial_fixation_state_duration)]);
        disp(['Fixation Duration M1: ', num2str(initial_fixation_duration_m1)]);
        disp(['Fixation Duration M2: ', num2str(initial_fixation_duration_m2)]);
        disp(['ITI Duration: ', num2str(iti_duration)]);
        disp(['Initial Reward M1: ', num2str(initial_reward_m1)]);
        disp(['Initial Reward M2: ', num2str(initial_reward_m2)]);
        disp(['Initial Reward M1 & M2: ', num2str(init_reward_m1_m2)]);
        disp(['Error Duration: ', num2str(error_duration)]);
        disp(['Name of M1: ', name_of_m1]);
        disp(['Name of M2: ', name_of_m2]);
        disp(['Fix Cross Visu Angl: ', num2str(fix_cross_visu_angl)]);
        disp(['Total Distance M1: ', num2str(totdist_m1)]);
        disp(['Total Distance M2: ', num2str(totdist_m2)]);
        disp(['Screen Height Left: ', num2str(screen_height_left)]);
        disp(['Padding Angle: ', num2str(padding_angl)]);
        disp(['Enable Remap: ', num2str(enable_remap)]);
        disp(['Save Data: ', num2str(save_data)]);
        disp(['Full Screens: ', num2str(full_screens)]);
        disp(['Max Number of Trials: ', num2str(max_num_trials)]);
        disp(['Play feedback sound: ', num2str(play_feedback_sound)]);
        disp(['Saved file directory: ', num2str(proj_p)]);
        
        % Call the task function with the parameters
        social_coordination_task(useEyeROI, m2_eye_roi_padding_x, m2_eye_roi_padding_y, ...
            m2_face_roi_padding_x, m2_face_roi_padding_y,initial_fixation_state_duration, initial_fixation_duration_m1, ...
            initial_fixation_duration_m2, iti_duration, initial_reward_m1, ...
            initial_reward_m2, init_reward_m1_m2, error_duration, name_of_m1, ...
            name_of_m2, fix_cross_visu_angl, totdist_m1, totdist_m2, ...
            screen_height_left, padding_angl, enable_remap, save_data, full_screens, max_num_trials, play_feedback_sound,proj_p);
    end
end
