import os
import google.generativeai as genai
from flask import Flask, request, jsonify
import time

# --- Configuration ---
# Set your Google AI API Key here
# It's recommended to use environment variables for production
genai.configure(api_key="AIzaSyBPMi7QoVJKom2o5BV4eZfDGHBHE0_o6_g")

# Create a folder to temporarily store video uploads
UPLOAD_FOLDER = 'uploads'
if not os.path.exists(UPLOAD_FOLDER):
    os.makedirs(UPLOAD_FOLDER)

app = Flask(__name__)
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

# --- The Prompt for Gemini ---
# This is the most important part. We instruct the model on its role,
# the context, and the desired output format (JSON).
SYSTEM_PROMPT = """
You are a world-class tennis coach and an expert NTRP (National Tennis Rating Program) evaluator.
Your task is to analyze a video of a tennis player and provide a detailed, constructive assessment.

Analyze the player's strokes (forehand, backhand, serve), footwork, and overall strategy based on the provided video.

Based on your analysis, you must provide:
1.  An estimated NTRP rating between 1.0 and 7.0.
2.  A brief justification for the rating.
3.  Specific, actionable training advice for their forehand, backhand, and serve to help them improve.

You MUST return your response in a clean, minified JSON object with the following exact structure:
{
  "ntrp_level": "...",
  "justification": "...",
  "training_advice": {
    "forehand": "...",
    "backhand": "...",
    "serve": "...",
    "footwork": "..."
  }
}
"""

# --- The Main Route ---
@app.route('/analyze', methods=['POST'])
def analyze_video_route():
    # 1. Validate the incoming request
    if 'video' not in request.files:
        return jsonify({'error': 'No video file provided in the request.'}), 400

    video_file = request.files['video']

    if video_file.filename == '':
        return jsonify({'error': 'No file selected.'}), 400

    try:
        # 2. Save the video file temporarily
        video_path = os.path.join(app.config['UPLOAD_FOLDER'], video_file.filename)
        video_file.save(video_path)

        # 3. Upload the file to the Google AI File API
        print(f"Uploading file to Google: {video_path}")
        tennis_video_file = genai.upload_file(path=video_path)

        # The File API can take a moment to process the video.
        # We need to wait until the video is in an 'ACTIVE' state.
        while tennis_video_file.state.name == "PROCESSING":
            print("Video is still processing...")
            time.sleep(10) # Wait 10 seconds before checking again
            tennis_video_file = genai.get_file(tennis_video_file.name)

        if tennis_video_file.state.name != "ACTIVE":
             return jsonify({'error': f'Video processing failed with state: {tennis_video_file.state.name}'}), 500

        # 4. Prompt Gemini with the video
        print("File uploaded and processed. Prompting Gemini...")
        model = genai.GenerativeModel(
            model_name="gemini-2.5-pro", # Or gemini-2.5-pro when available
            system_instruction=SYSTEM_PROMPT
        )
        
        response = model.generate_content([tennis_video_file])

        # 5. Clean up and return the response
        # Delete the uploaded file from Google's servers and our local server
        genai.delete_file(tennis_video_file.name)
        os.remove(video_path)
        
        print("Successfully received response from Gemini.")
        # The response.text should be a JSON string based on our prompt
        return response.text, 200

    except Exception as e:
        print(f"An error occurred: {e}")
        return jsonify({'error': str(e)}), 500

# --- Run the App ---
if __name__ == '__main__':
    # Use 0.0.0.0 to make it accessible from your local network (e.g., your iPhone)
    app.run(host='0.0.0.0', port=5001, debug=True)