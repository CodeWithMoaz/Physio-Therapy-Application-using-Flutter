from fastapi import FastAPI, File, UploadFile
from fastapi.middleware.cors import CORSMiddleware
import pytesseract
from PIL import Image
import io
import re
import cv2
import numpy as np
from typing import Dict

app = FastAPI()


app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],  
)


pytesseract.pytesseract.tesseract_cmd = r"C:\Program Files\Tesseract-OCR\tesseract.exe"

def preprocess_image(img_pil):
    
    img_np = np.array(img_pil)
    
    
    if len(img_np.shape) == 3 and img_np.shape[2] == 3:
        gray = cv2.cvtColor(img_np, cv2.COLOR_RGB2GRAY)
    else:
        
        gray = img_np
    
    
    resized = cv2.resize(gray, None, fx=1.5, fy=1.5, interpolation=cv2.INTER_LINEAR)
    
   
    processed_image = cv2.adaptiveThreshold(
        resized, 
        255, 
        cv2.ADAPTIVE_THRESH_GAUSSIAN_C, 
        cv2.THRESH_BINARY, 
        63, 
        12
    )
    
    return processed_image

def get_field(field_name: str, text: str) -> str:
    pattern_dict = {
        "patient_name": {"pattern": r"(?:PatientName|Patient Name|Name|Patient)\s*(?:\[|:)\s*([A-Za-z\s]+)", "flags": re.IGNORECASE},
        "patient_age": {"pattern": r"Age\s*:\s*(\d+\s*(?:Y|Years|Year)?)", "flags": re.IGNORECASE},
        "patient_sex": {"pattern": r"(?:Sex|Gender)\s*:\s*(\w+)", "flags": re.IGNORECASE},
        "technique": {"pattern": r"(?:TECHNIQUE:|TECHNIQUE|Protocol):\s*(.*?)(?=\s*(?:OBSERVATION:|FINDINGS:|$))", "flags": re.DOTALL | re.IGNORECASE},
        "findings": {"pattern": r"(?:FINDINGS:|Findings:)\s*(.*?)(?=\s*(?:IMPRESSION:|Impression:|$))", "flags": re.DOTALL | re.IGNORECASE},
        "impression": {"pattern": r"(?:IMPRESSION:|Impression:)\s*(.*?)(?=\s*(?:Adv\.|$))", "flags": re.DOTALL | re.IGNORECASE},
        "referred_by": {"pattern": r"(?:Referred by|Referring Physician)\s*(?::|=)?\s*([^\.]+?)(?=\.|$)", "flags": re.IGNORECASE},
        "injury_location": {"pattern": r"(?:Injury Location|Site of pain|Region|Area)\s*(?::|=)?\s*([^\.]+?)(?=\.|$)", "flags": re.IGNORECASE},
        "injury_severity": {"pattern": r"Injury Severity\s*(?::|=)?\s*([^\.]+?)(?=\.|$)", "flags": re.IGNORECASE},
        "imaging_results": {"pattern": r"Imaging Results\s*(?::|=)?\s*([^\.]+?)(?=\.|$)", "flags": re.DOTALL | re.IGNORECASE},
        "diagnosis": {"pattern": r"(?:Diagnosis|Assessment)\s*(?::|=)?\s*([^\.]+?)(?=\.|$)", "flags": re.IGNORECASE},
        "recommendations": {"pattern": r"(?:Adv\.|Recommendations|Plan|Treatment)\s*(.*?)(?=\s*(?:Reported by|$))", "flags": re.DOTALL | re.IGNORECASE},
        "date_of_exam": {"pattern": r"(?:Report Time|Date|Exam Date)\s*(?::|=)?\s*([\d/\-\.]+(?:\s*[\d:]+)?)", "flags": re.IGNORECASE},
        "physician_name": {"pattern": r"(?:DR\.|Doctor|Physician|Radiologist)\s*([^,\n]+)", "flags": re.IGNORECASE},
        "history": {"pattern": r"(?:History|Clinical History)\s*(?::|=)?\s*([^\.]+?)(?=\.|$)", "flags": re.DOTALL | re.IGNORECASE},
        "clinical_exam": {"pattern": r"Clinical Exam\s*(?::|=)?\s*([^\.]+?)(?=\.|$)", "flags": re.DOTALL | re.IGNORECASE},
        "procedure": {"pattern": r"(?:MRI of|MRI OF|MRI -|Examination|Procedure)\s*(.*?)(?=\s*\d|\n|Clinical|$)", "flags": re.IGNORECASE},
        "comparison": {"pattern": r"Comparison\s*(?::|=)?\s*([^\.]+?)(?=\.|$)", "flags": re.DOTALL | re.IGNORECASE},
        "conclusion": {"pattern": r"Conclusion\s*(?::|=)?\s*([^\.]+?)(?=\.|$)", "flags": re.DOTALL | re.IGNORECASE},
        "clinical_information": {"pattern": r"(?:Clinical Information|History|Clinical)\s*(?::|=)?\s*([^\.]+?)(?=\.|Findings:|$)", "flags": re.DOTALL | re.IGNORECASE},
        "observations": {"pattern": r"(?:OBSERVATION:|Observations:)\s*(.*?)(?=\s*(?:IMPRESSION:|Conclusion:|$))", "flags": re.DOTALL | re.IGNORECASE},
    }

    pattern_object = pattern_dict.get(field_name)
    if pattern_object:
        matches = re.findall(pattern_object["pattern"], text, flags=pattern_object["flags"])
        if len(matches) > 0:
            return matches[0].strip()
    return ""

def parse(text: str) -> Dict:
    return {
        "patient_name": get_field("patient_name", text),
        "patient_age": get_field("patient_age", text),
        "patient_sex": get_field("patient_sex", text),
        "technique": get_field("technique", text),
        "findings": get_field("findings", text),
        "impression": get_field("impression", text),
        "referred_by": get_field("referred_by", text),
        "injury_location": get_field("injury_location", text),
        "injury_severity": get_field("injury_severity", text),
        "imaging_results": get_field("imaging_results", text),
        "diagnosis": get_field("diagnosis", text),
        "recommendations": get_field("recommendations", text),
        "date_of_exam": get_field("date_of_exam", text),
        "physician_name": get_field("physician_name", text),
        "history": get_field("history", text),
        "clinical_exam": get_field("clinical_exam", text),
        "procedure": get_field("procedure", text),
        "comparison": get_field("comparison", text),
        "conclusion": get_field("conclusion", text),
        "clinical_information": get_field("clinical_information", text),
        "observations": get_field("observations", text),  
    }

@app.post("/extract-text/")
async def extract_text(file: UploadFile = File(...)):
    try:
        print(f"Received file: {file.filename}")
        
        image_bytes = await file.read()
        print(f"File size: {len(image_bytes)} bytes")
        
        image = Image.open(io.BytesIO(image_bytes))
        
        processed_image = preprocess_image(image)
        
        raw_text = pytesseract.image_to_string(image, lang="eng")
        processed_text = pytesseract.image_to_string(processed_image, lang="eng")
        
        final_text = processed_text if len(processed_text) > len(raw_text) else raw_text
        print(f"Extracted text length: {len(final_text)}")
        
        parsed_data = parse(final_text)
        
        return {
            "extracted_text": final_text,
            "parsed_data": parsed_data
        }
    except Exception as e:
        print(f"Error processing image: {str(e)}")
        return {"error": str(e)}

@app.get("/")
async def root():
    return {"message": "Medical report extraction service is running"}