import numpy as np

def generate_data():
    sizes = np.random.randint(0, 4, size=50)
    elements = []
    for size in sizes:
        matrix_size = 2 ** (size + 1)
        num_elements = 32 * (matrix_size ** 2)  # 计算元素数量
        matrix_elements = np.random.randint(-128, 128, size=num_elements)
        elements.append(matrix_elements)

    # 生成mode和index
    modes = np.random.randint(0, 4, size=500)  # 50组数据，每组10次
    indices = np.random.randint(0, 32, size=(500, 3))  # 每次3个index

    # 输出到文件
    np.savetxt('size.txt', sizes, fmt='%d')
    with open('element.txt', 'w') as f:
        for element_group in elements:
            matrix_size = int(np.sqrt(len(element_group) / 32))
            for i in range(32):
                matrix = element_group[i * (matrix_size ** 2):(i + 1) * (matrix_size ** 2)]
                f.write(' '.join(map(str, matrix.reshape(matrix_size, matrix_size).flatten())) + '\n')
            f.write('\n')  # 矩阵之间留空行
    np.savetxt('mode.txt', modes, fmt='%d')
    np.savetxt('index.txt', indices, fmt='%d')

def read_data():
    with open('size.txt', 'r') as f:
        sizes = [int(line.strip()) for line in f]

    with open('element.txt', 'r') as f:
        elements = []
        matrix_group = []
        for line in f:
            if line.strip():
                matrix = np.fromstring(line.strip(), dtype=int, sep=' ')
                matrix_group.append(matrix)
                if len(matrix_group) == 32:
                    elements.append(matrix_group)
                    matrix_group = []
        if matrix_group:
            elements.append(matrix_group)

    with open('mode.txt', 'r') as f:
        modes = [int(line.strip()) for line in f]

    with open('index.txt', 'r') as f:
        indices = []
        for line in f:
            indices.append(list(map(int, line.strip().split())))

    return sizes, elements, modes, indices

def calculate_trace(A, B, C, mode):
    if mode == 0:
        product = np.dot(np.dot(A, B), C)
    elif mode == 1:
        product = np.dot(np.dot(A.T, B), C)
    elif mode == 2:
        product = np.dot(A, np.dot(B.T, C))
    elif mode == 3:
        product = np.dot(np.dot(A, B), C.T)
    return np.trace(product)

def main():
    sizes, elements, modes, indices = read_data()
    all_traces = []

    for group in range(50):
        size = sizes[group]
        matrix_size = 2 ** (size + 1)  # 计算矩阵大小

        matrices = elements[group]

        current_traces = []

        for i in range(10):
            mode = modes[group * 10 + i]
            index_set = indices[group * 10 + i]

            try:
                # 确保矩阵是正确的大小
                A = matrices[index_set[0]].reshape(matrix_size, matrix_size)
                B = matrices[index_set[1]].reshape(matrix_size, matrix_size)
                C = matrices[index_set[2]].reshape(matrix_size, matrix_size)

                trace = calculate_trace(A, B, C, mode)
                current_traces.append(trace)
            except Exception as e:
                print(f"Error processing group {group}, iteration {i}: {e}. Index set: {index_set}, Expected size: {matrix_size}")

        all_traces.append(current_traces)

    with open('ams.txt', 'w') as f:
        for trace_group in all_traces:
            for trace in trace_group:
                f.write(f"{trace}\n")

if __name__ == "__main__":
    generate_data()  # 生成数据
    main()  # 读取数据并计算
