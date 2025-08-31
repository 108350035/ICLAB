import numpy as np

def generate_data():
    sizes = []
    elements = []
    modes = []
    indices = []

    for _ in range(50):
        size = np.random.randint(0, 4)  # 随机生成size
        sizes.append(size)

        # 根据size计算矩阵大小
        matrix_size = 2 ** (size + 1)
        total_elements = 32 * (matrix_size ** 2)  # 计算需要生成的元素数量

        # 生成矩阵元素
        elements_group = np.random.randint(-128, 128, size=total_elements)

        # 按照矩阵的样式输出
        element_matrices = []
        for i in range(32):
            start_idx = i * (matrix_size ** 2)
            end_idx = start_idx + (matrix_size ** 2)
            matrix_elements = elements_group[start_idx:end_idx].reshape(matrix_size, matrix_size)
            element_matrices.append(matrix_elements)

        # 添加矩阵到元素列表
        elements.append(element_matrices)

        # 随机生成10个mode和对应的3个index
        mode_group = []
        index_group = []
        for _ in range(10):
            mode = np.random.randint(0, 4)
            mode_group.append(mode)
            indices_set = np.random.choice(32, 3, replace=True)  # 随机选择3个索引
            index_group.append(indices_set)

        modes.append(mode_group)
        indices.append(index_group)

    # 保存到文件
    with open('size.txt', 'w') as f:
        for size in sizes:
            f.write(f"{size}\n")

    with open('element.txt', 'w') as f:
        for element_matrices in elements:
            for matrix in element_matrices:
                np.savetxt(f, matrix, fmt='%d', delimiter=' ')
                f.write("\n")  # 矩阵之间留空行
            f.write("\n")  # 每组矩阵之间留空行

    with open('mode.txt', 'w') as f:
        for mode_group in modes:
            for mode in mode_group:
                f.write(f"{mode}\n")

    with open('index.txt', 'w') as f:
        for index_group in indices:
            for indices_set in index_group:
                f.write(f"{indices_set[0]} {indices_set[1]} {indices_set[2]}\n")

generate_data()
