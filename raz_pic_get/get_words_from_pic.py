# brew install tesseract
# pip install pytesseract Pillow 

import os
import shutil
from PIL import Image
import pytesseract

import os
import shutil
from PIL import Image
import pytesseract
from datetime import datetime

def get_unique_filename(output_folder, base_name, extension):
    counter = 1
    new_filename = f"{base_name}{extension}"
    while os.path.exists(os.path.join(output_folder, new_filename)):
        new_filename = f"{base_name}_{counter}{extension}"
        counter += 1
    return new_filename

def extract_text_from_bottom_of_image(image_path):
    # 打开图片并转换为灰度图像以提高 OCR 准确度
    image = Image.open(image_path).convert('L')
    width, height = image.size
    
    # 裁剪图片底部区域，假设底部 20% 高度是包含单词的位置
    bottom_height = int(height * 0.25)
    cropped_image = image.crop((0, height - bottom_height, width, height))
    
    
    current_time = datetime.now().strftime('%Y-%m-%d_%H-%M-%S_%f')
//    cropped_image.save("/Users/weipingjie/Desktop/my_app/ios_dev_git/ios_dev/raz_pic_get/words_pic/" + current_time + ".png")
    # 使用 Tesseract 进行 OCR 识别
    text = pytesseract.image_to_string(cropped_image)
    
    
    # 提取英文单词并过滤掉非英文字符
    words = text.split()
    english_words = [word for word in words if word.isalpha()]
    
    # 如果有多个单词，选择第一个作为文件名
    if english_words:
        return english_words[0]
    else:
        return None

def process_images(input_folder, output_folder):
    # 如果输出文件夹不存在，创建它
    if not os.path.exists(output_folder):
        os.makedirs(output_folder)
    
    # 遍历输入文件夹中的所有图片
    for filename in os.listdir(input_folder):
        if filename.lower().endswith(('.png', '.jpg', '.jpeg', '.bmp', '.tiff')):
            image_path = os.path.join(input_folder, filename)
            extracted_word = extract_text_from_bottom_of_image(image_path)
            
            if extracted_word:
                # 使用提取的单词作为新文件名
                #new_filename = f"{extracted_word}.png"  # 这里可以根据需求改为原文件的扩展名
                new_filename = get_unique_filename(output_folder, extracted_word, '.png')

                output_path = os.path.join(output_folder, new_filename)
                
                # 复制图片到新路径
                shutil.copy(image_path, output_path)
                print(f"复制图片: {filename} -> {new_filename}")
            else:
                print(f"未提取到有效单词: {filename}")


# 指定输入文件夹和输出文件夹路径
input_folder = './origin_pic/'
output_folder = './words_pic/'

# 处理图片
process_images(input_folder, output_folder)

