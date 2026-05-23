"""
Captura screenshots de todos os slides via RawSlideScreen.
URL: http://localhost:7410/?view=raw&n=INDEX (base 0)
Viewport: 820x347 (real)
Clip: x=102, y=0, width=617, height=347
"""

import os
import sys
import time
from playwright.sync_api import sync_playwright

BASE_URL = "http://localhost:7410"
OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "..", "artifacts", "actual_slides")
SLIDE_COUNT = 16
CLIP = {"x": 102, "y": 0, "width": 617, "height": 347}

def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page(viewport={"width": 820, "height": 347})
        
        for i in range(SLIDE_COUNT):
            url = f"{BASE_URL}/?view=raw&n={i}"
            page.goto(url)
            # Wait for fonts + rendering
            page.wait_for_load_state("networkidle")
            time.sleep(1.5)
            
            filename = f"slide_{i+1:03d}.png"
            out_path = os.path.join(OUTPUT_DIR, filename)
            page.screenshot(path=out_path, clip=CLIP)
            print(f"Captured slide {i+1}/{SLIDE_COUNT}: {filename}")
        
        browser.close()
    
    print(f"\nDone! Screenshots saved to: {OUTPUT_DIR}")

if __name__ == "__main__":
    main()
