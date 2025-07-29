import os
import cv2  # OpenCV for video processing
import mediapipe as mp # MediaPipe for pose estimation
import google.generativeai as genai
from flask import Flask, request, jsonify

# --- Configuration ---
# Get the API Key from environment variables (important for deployment)
api_key = os.environ.get('GOOGLE_API_KEY')
genai.configure(api_key=api_key)

# Create a folder to temporarily store video uploads
UPLOAD_FOLDER = 'uploads'
if not os.path.exists(UPLOAD_FOLDER):
    os.makedirs(UPLOAD_FOLDER)

app = Flask(__name__)
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

# --- MediaPipe Pose Processing Function (The New Core Logic) ---

def process_video_with_mediapipe(video_path):
    """
    Analyzes a video file to extract pose landmarks using MediaPipe.
    
    Args:
        video_path: The file path of the video to process.

    Returns:
        A list of dictionaries, where each dictionary represents the
        landmarks of the first detected person in a frame.
        Returns an empty list if no poses are detected.
    """
    print("--- Starting MediaPipe processing... ---")
    
    # Initialize MediaPipe components
    mp_pose = mp.solutions.pose
    pose = mp_pose.Pose(static_image_mode=False, min_detection_confidence=0.5)
    
    # Use OpenCV to open the video file
    cap = cv2.VideoCapture(video_path)
    
    all_landmarks = []
    frame_count = 0
    
    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break

        # We can process every Nth frame to speed things up even more.
        # Let's process every 5th frame.
        if frame_count % 15 == 0:
            # Convert the frame to RGB, as MediaPipe expects it
            image_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            
            # Process the frame and get the pose results
            results = pose.process(image_rgb)
            
            # If a pose is detected, extract the landmarks
            if results.pose_landmarks:
                frame_landmarks = []
                for landmark in results.pose_landmarks.landmark:
                    frame_landmarks.append({
                        'x': landmark.x,
                        'y': landmark.y,
                        'z': landmark.z,
                        'visibility': landmark.visibility
                    })
                all_landmarks.append({'frame': frame_count, 'landmarks': frame_landmarks})

        frame_count += 1
        
    # Clean up
    cap.release()
    pose.close()
    
    print(f"--- MediaPipe processing finished. Found poses in {len(all_landmarks)} frames. ---")
    return all_landmarks

# --- The Main Flask Route (Now Modified) ---

@app.route('/analyze', methods=['POST'])
def analyze_video_route():
    print("\n--- A. /analyze endpoint hit! ---") 
    
    if 'video' not in request.files:
        return jsonify({'error': 'No video file provided'}), 400

    video_file = request.files['video']
    if video_file.filename == '':
        return jsonify({'error': 'No selected file'}), 400

    try:
        # 1. Save the video file temporarily
        video_path = os.path.join(app.config['UPLOAD_FOLDER'], video_file.filename)
        video_file.save(video_path)
        print(f"--- B. Video saved temporarily to {video_path} ---")

        # 2. Pre-process the video with MediaPipe to get pose data
        # THIS IS THE NEW, CRUCIAL STEP
        pose_data = process_video_with_mediapipe(video_path)

        if not pose_data:
            os.remove(video_path) # Clean up the saved video
            return jsonify({'error': 'Could not detect a person in the video.'}), 400

        # 3. Create a new text-based prompt for Gemini
        # We are no longer uploading the video file!
        prompt = f"""
        You are a world-class tennis coach and an expert NTRP (National Tennis Rating Program) evaluator.
        Your task is to analyze a tennis player's movements based on a structured JSON object containing their
        pose landmarks over several frames of a video. Each landmark has x, y, z, and visibility coordinates.
        The player's forehand, backhand, and serve motions are contained within this data.

        Based on your analysis of this motion data, you must provide:
        1. An estimated NTRP rating between 1.0 and 7.0.
        2. A brief justification for the rating based on the inferred movements (e.g., "The data shows a compact backswing on the forehand," "The arm extension on the serve, inferred from elbow and wrist positions, is limited").
        3. Specific, actionable training advice for their forehand, backhand, and serve.

        You MUST return your response in a clean, minified JSON object with the following exact structure:
        {{"ntrp_level": "...", "justification": "...", "training_advice": {{"forehand": "...", "backhand": "...", "serve": "...", "footwork": "..."}}}}

        Here is the pose data:
        {str(pose_data)}
        """

        # 4. Prompt Gemini with the text and pose data
        print("--- C. Sending text prompt with pose data to Gemini... ---")
        model = genai.GenerativeModel('gemini-2.5-pro') # Or your preferred model
        response = model.generate_content(prompt)
        
        # 5. Clean up the local video file and return the response
        os.remove(video_path)
        print("--- D. Successfully received response from Gemini. ---")
        return response.text, 200

    except Exception as e:
        # Clean up the file in case of an error
        if 'video_path' in locals()x and os.path.exists(video_path):
            os.remove(video_path)
        print(f"--- X. An error occurred: {e} ---")
        return jsonify({'error': str(e)}), 500

# The Gunicorn command in the terminal is now the only way to run this.
# The if __name__ == '__main__': block should be removed.