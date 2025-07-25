from PIL import Image
import serial
import numpy as np

dim = 128

img = Image.open('tempio.jpg').convert('L')

# resize the image to fit in fpga BRAM
img = img.resize((dim, dim))

image_in = img.tobytes()


ser = serial.Serial(port='/dev/ttyUSB1', baudrate=115200)

ser.write(image_in)

print('image sent to fpga')

image_out = ser.read(dim*dim)

print('image filtered')

image_filtered = np.frombuffer(image_out, dtype=np.uint8).reshape((dim, dim))
image_filtered = Image.fromarray(image_filtered, mode='L')
image_filtered.save('tempio_sobel.png')

ser.close()
