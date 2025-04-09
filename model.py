# model.py
import io
from typing import Dict
from PIL import Image
import pytesseract
import kserve
from kserve import Model, ModelServer, InferRequest, InferResponse, InferInput, InferOutput
from kserve.utils.utils import generate_uuid
import base64

class OCRModel(Model):
    def __init__(self, name: str):
        super().__init__(name)
        self.name = name
        self.ready = True  # Model is ready to serve

    async def predict(self, infer_request: InferRequest, headers: Dict[str, str] = None) -> InferResponse:
        # Extract the binary image data from the inference request
        input_tensor = infer_request.inputs[0]
        base64_image_data = input_tensor.data[0]  # Base64 encoded string

        # Decode base64 string to bytes
        image_data = base64.b64decode(base64_image_data)

        # Open the image using PIL
        image = Image.open(io.BytesIO(image_data))

        # Use Tesseract to extract text from the image
        extracted_text = pytesseract.image_to_string(image)

        # Prepare the inference response
        response_id = generate_uuid()
        output = InferOutput(
            name="output-0",
            shape=[1],
            datatype="BYTES",
            data=extracted_text # Base64 encode the output string
        )
        infer_response = InferResponse(
            model_name=self.name,
            infer_outputs=[output],
            response_id=response_id
        )
        return infer_response

if __name__ == "__main__":
    model = OCRModel("ocr-model")
    ModelServer().start([model])