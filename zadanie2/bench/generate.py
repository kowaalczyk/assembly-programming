#!python3
# usage: python3 ./bench/generate.py 2 3 0.01 4 > ./bench/bench_iter_4.in

import sys

if __name__ == '__main__':
    if len(sys.argv) != 5:
        raise ValueError("Expected arguments: int width, int height, float weight, int iterations")

    width = int(sys.argv[1])
    height = int(sys.argv[2])
    weight = float(sys.argv[3])
    iterations = int(sys.argv[4])

    print(f"{width} {height} {weight}")
    for row in range(height):
        print(" ".join(["1.0"] * width))

    print(f"{iterations}")
    for i in range(iterations):
        print(" ".join(["100.0"] * height))
