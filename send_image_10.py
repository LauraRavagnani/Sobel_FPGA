import serial
import numpy as np
import time

dim = 10

matrix =np.array([[i+dim*j for i in range(dim)] for j in range(dim)])
#matrix = np.random.randint(16, (dim, dim))
matrix_bin = matrix.flatten().tolist()

print(matrix)
	
ser = serial.Serial(port='/dev/ttyUSB1', baudrate=115200, timeout=1)

#for i in range(dim*dim):
#	ser.write(bytes([matrix_bin[i]]))
#	time.sleep(0.3)	

ser.write(bytearray(matrix_bin))

ser.close()
