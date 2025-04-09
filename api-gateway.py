from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.responses import JSONResponse
import requests
import base64
import json
import os
app = FastAPI()

import os

# Get the KServe URL from environment, or use default
KSERVE_URL = os.environ.get("KSERVE_URL", "http://localhost:8080/v2/models/ocr-model/infer") # Your KServe model server URL

@app.post("/gateway/ocr")
async def gateway_ocr_request(image_file: UploadFile = File(...)):
    """
    Proxies OCR requests from Postman to the KServe model server.
    Expects an image file upload.
    """
    try:
        # 1. Read image file content as bytes
        image_data = await image_file.read()

        # 2. Base64 encode the image data
        base64_image_data = base64.b64encode(image_data).decode('utf-8')

        # 3. Construct the KServe inference request
        infer_request = {
            "inputs": [
                {
                    "name": "input-0",
                    "shape": [1],
                    "datatype": "BYTES",
                    "data": [base64_image_data],
                    "parameters": {"content_type": image_file.content_type} # Use content type from uploaded file
                }
            ]
        }

        # 4. Convert the request to JSON
        json_request = json.dumps(infer_request)

        # 5. Set headers for KServe request
        headers = {'Content-Type': 'application/json'}

        # 6. Forward the request to the KServe model server
        response = requests.post(KSERVE_URL, headers=headers, data=json_request)

        # 7. Check KServe server response status
        if response.status_code != 200:
            raise HTTPException(status_code=response.status_code, detail=response.text)

        # 8. Return the KServe server's JSON response back to Postman
        return JSONResponse(content=response.json())

    except HTTPException as http_exc:
        raise http_exc  # Re-raise HTTP exceptions from requests.post
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001) # Run FastAPI app on port 8001 (or any port you prefer)