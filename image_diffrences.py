import cv2
import numpy as np
import os

def compare_images(reference_path, test_path, output_folder='output', threshold=30, min_area=100):
    """
    Compare two images and highlight differences.

    Parameters:
    - reference_path: str, path to the reference image
    - test_path: str, path to the image to compare
    - output_folder: str, folder to save output image with differences
    - threshold: int, pixel difference threshold for highlighting
    - min_area: int, minimum contour area to consider a difference significant

    Returns:
    - images_match: bool, True if images match, False if differences found
    - output_path: str, path to the saved output image
    """
    os.makedirs(output_folder, exist_ok=True)
    output_path = os.path.join(output_folder, 'image_diff.png')

    # Load images
    img1 = cv2.imread(reference_path)
    img2 = cv2.imread(test_path)

    if img1 is None or img2 is None:
        raise FileNotFoundError("One of the images could not be loaded. Check the path.")

    # Resize test image if sizes don't match
    if img1.shape != img2.shape:
        img2 = cv2.resize(img2, (img1.shape[1], img1.shape[0]))

    # Convert to grayscale
    gray1 = cv2.cvtColor(img1, cv2.COLOR_BGR2GRAY)
    gray2 = cv2.cvtColor(img2, cv2.COLOR_BGR2GRAY)

    # Compute absolute difference
    diff = cv2.absdiff(gray1, gray2)

    # Threshold the difference
    _, thresh = cv2.threshold(diff, threshold, 255, cv2.THRESH_BINARY)

    # Dilate to merge nearby differences
    kernel = np.ones((5,5), np.uint8)
    dilated = cv2.dilate(thresh, kernel, iterations=2)

    # Find contours
    contours, _ = cv2.findContours(dilated, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

    images_match = True

    # Draw bounding boxes on test image
    for contour in contours:
        if cv2.contourArea(contour) > min_area:
            x, y, w, h = cv2.boundingRect(contour)
            cv2.rectangle(img2, (x, y), (x+w, y+h), (0, 0, 255), 2)
            images_match = False

    # Save output image
    cv2.imwrite(output_path, img2)

    return images_match, output_path


# Example usage
if __name__ == "__main__":
    ref_img = r'.\input_image\IN06-030124-PR-002_0001.png'
    test_img = r'.\input_image\IN06-030124-PR-002_0001_test.jpg'

    match, out_path = compare_images(ref_img, test_img)
    if match:
        print("Images match. No significant differences found.")
    else:
        print("Images do NOT match. Differences highlighted.")
    print(f"Output saved at: {out_path}")
