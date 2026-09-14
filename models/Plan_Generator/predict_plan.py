import tensorflow as tf
import numpy as np
import pandas as pd
from sklearn.preprocessing import StandardScaler, LabelEncoder
import os

def load_model_and_scalers():
    model_directory = os.path.dirname(os.path.abspath(__file__))
    model_path = os.path.join(model_directory, 'exercise_recommendation_model.h5')
    if not os.path.exists(model_path):
        raise FileNotFoundError(f'Model file not found at {model_path}')
    
    try:
        model = tf.keras.models.load_model(model_path)
    except Exception as e:
        print(f'Error loading TensorFlow model: {e}')
        raise 
    

    dataset_path = os.path.join(model_directory, 'final_dataset.csv')
    if not os.path.exists(dataset_path):
         raise FileNotFoundError(f'Dataset file not found at {dataset_path}')
    
    try:
        df = pd.read_csv(dataset_path)
    except Exception as e:
        print(f'Error loading dataset: {e}')
        raise 
    
  
    X = df[['Weight', 'Height', 'Age']]
    scaler = StandardScaler()
    scaler.fit(X[['Weight', 'Height', 'Age']])
    
    
    le_gender = LabelEncoder()
    le_gender.fit(df['Gender'])
    
    return model, scaler, le_gender

def get_plan_details(plan_number):
    """
    Returns details about the exercise plan based on the plan number
    """
    plans = {
        0: "0",
        1: "Severe Thinness Plan",
        2: "Moderate Thinness Plan",
        3: "Mild Thinness Plan",
        4: "Normal Weight Plan",
        5: "Overweight Plan",
        6: "Obesity Plan",
        7: "Severe Obesity Plan"
    }
    return plans.get(plan_number, "Unknown Plan")

def predict_exercise_plan(weight, height_meters, gender, age):
    """
    Predict exercise recommendation plan for given parameters
    
    Parameters:
    weight (float): Weight in kg
    height_meters (float): Height in meters
    gender (str): 'Male' or 'Female'
    age (int): Age in years
    
    Returns:
    dict: Dictionary containing prediction details
    """
    
    global model, scaler, le_gender
    
    try:
        numerical_input = np.array([[weight, height_meters, age]])
        gender_encoded = le_gender.transform([gender])[0]

        numerical_scaled = scaler.transform(numerical_input)

        input_data = np.array([[numerical_scaled[0, 0], numerical_scaled[0, 1], numerical_scaled[0, 2], gender_encoded]])

     
        prediction_proba = model.predict(input_data, verbose=0)
        predicted_class = np.argmax(prediction_proba, axis=1)[0]
        confidence = np.max(prediction_proba)
        
    
        plan_name = get_plan_details(predicted_class)
        
        
        probabilities = {
            get_plan_details(i): float(prob)
            for i, prob in enumerate(prediction_proba[0])
        }
        
        return {
            "plan_number": int(predicted_class),
            "plan_name": plan_name,
            "confidence": float(confidence),
            "probabilities": probabilities
        }
    except Exception as e:
        print(f'Error during prediction: {e}')
        raise 


try:
    model, scaler, le_gender = load_model_and_scalers()
    print('Model and scalers loaded successfully.')
except Exception as e:
    print(f'Failed to load model and scalers on startup: {e}')
   


if __name__ == "__main__":
 
    weight = 70  
    height = 1.75  
    gender = "Male"
    age = 30
    
    try:
        result = predict_exercise_plan(weight, height, gender, age)
        print(f"Predicted Exercise Plan: {result['plan_name']} (Plan {result['plan_number']})")
        print(f"Confidence: {result['confidence']:.2%}")
        print("\nProbabilities for each plan:")
        for plan, prob in result['probabilities'].items():
            print(f"{plan}: {prob:.2%}")
    except Exception as e:
        print(f"Error during example prediction: {e}") 