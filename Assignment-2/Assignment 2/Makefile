
CPPCOMP := g++
CPPFLAGS := -Wno-deprecated-declarations

CUCOMP := nvcc
CUFLAGS := --gpu-architecture=compute_35

pattern:
	${CPPCOMP} pattern_CPU.cpp -o pattern ${CPPFLAGS}
	# ${CUCOMP} GPU_Pattern.cu -o gpu_pattern

clean:
	rm -rf pattern
	# rm -rf gpu_pattern
