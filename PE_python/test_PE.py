from PE import PE

DILITHIUM_or_KYBER = 0
security_level = 0
pe = PE(DILITHIUM_or_KYBER, security_level)

# Test the decompose function
# Test the input from 0 to 8380416 and plot the output
import matplotlib.pyplot as plt
import numpy as np
x = np.arange(0, 8380416, 1)
print(pe.decompose(8380416))
y = [pe.decompose(i)[0] for i in x]
z = [pe.decompose(i)[1] for i in x]
plt.plot(x, y)
plt.show()
plt.plot(x, z)
plt.show()
# Test the decompose function by checking the input to output is one by one mapping
# Store the output in a list and check if the list is unique
# decomposed = []
# for i in range(8380416):
#     decomposed.append(pe.decompose(i))
# assert len(decomposed) == len(set(decomposed))


