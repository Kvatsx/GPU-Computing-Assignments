
# CPPCOMP := g++
# CPPFLAGS := -Wno-deprecated-declarations

# CUCOMP := nvcc
# CUFLAGS := --gpu-architecture=compute_35

# pattern:
# 	# ${CPPCOMP} pattern_CPU.cpp -o pattern ${CPPFLAGS}
# 	${CUCOMP} GPU_Pattern.cu -o gpu_pattern
# 	./gpu_pattern

# clean:
# 	# rm -rf pattern
# 	rm -rf gpu_pattern

all:
	nvcc -std=c++11 GPU_Pattern.cu
	# nvcc -std=c++11 pattern.cu
	./a.out

