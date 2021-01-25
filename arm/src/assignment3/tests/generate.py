import sys
from pathlib import Path


def change_color(in_path: str, out_path: str, color: int, delta: int):
    with open(in_path, 'r') as in_file:
        data = in_file.read().split()

    max_val = int(data[3])
    print(f"max_val={max_val}")
    for idx, value in enumerate(data[4:]):
        if idx % 3 == color:
            new_value = int(value) + delta
            if new_value < 0:
                new_value = 0
            if new_value > max_val:
                new_value = max_val
            data[idx + 4] = str(new_value)

    Path(out_path).parent.mkdir(exist_ok=True, parents=True)
    with open(out_path, 'w') as out_file:
        out_file.write("\n".join(data))
        out_file.write("\n")


if __name__ == '__main__':
    change_color(sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4]))
