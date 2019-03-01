# Kaustav Vats (2016048)

import matplotlib.pyplot as plt

# In[]
x = ["Small", "Medium", "Large"]
y = [
    [879.639, 911.311, 929.279],
    [237.498, 262.004, 277.582],
]
size = ["Kernel Timing", "Kernel + Memory Transfer"]
# kernel_3 = 
# kernel_5 = 
# kernel_7 = 
# kernel_9 = 
# kernel_11 = 

# In[]
color = ['b', 'r']
plt.figure()
for i in range(2):
    plt.plot(x, y[i][:], color[i], label="Speedup of %s"%size[i])
plt.ylabel("Speedups")
plt.xlabel("File Size")
plt.title("Pattern Matching Speedup Curve for different File Size")
plt.legend(loc='lower right')
# plt.show()
plt.savefig("speedup_curve.png")

#%%
