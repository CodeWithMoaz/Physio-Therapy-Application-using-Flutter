from flask import Flask, request, jsonify
from flask_cors import CORS
from predict_plan import predict_exercise_plan

app = Flask(__name__)
CORS(app)  

@app.route('/predict', methods=['POST'])
def predict():
    try:
        data = request.get_json()
        
        if not data:
            return jsonify({'error': 'Invalid JSON data'}), 400
            
      
        required_keys = ['weight', 'height_meters', 'gender', 'age']
        for key in required_keys:
            if key not in data:
                return jsonify({'error': f'Missing key: {key}'}), 400
        
        try:
            weight = float(data['weight'])
            height_meters = float(data['height_meters'])
            gender = str(data['gender'])
            age = int(data['age'])
        except ValueError as e:
             return jsonify({'error': f'Invalid data type: {e}'}), 400
        
     
        result = predict_exercise_plan(weight, height_meters, gender, age)
        
        return jsonify(result)
    
    except Exception as e:
       
        return jsonify({'error': f'An unexpected error occurred: {e}'}), 500 

if __name__ == '__main__':
    app.run(host='0.0.0.0', debug=False, port=5000)