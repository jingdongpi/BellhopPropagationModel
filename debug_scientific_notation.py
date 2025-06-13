#!/usr/bin/env python3
"""
深度调试科学计数法问题
"""
import json
import numpy as np

def debug_scientific_notation():
    """调试科学计数法问题的根本原因"""
    
    print("=== 科学计数法问题调试 ===\n")
    
    # 1. 测试不同的小数值
    test_values = [
        1.4e-05, -1.4e-05, 5.2e-05, -8e-06, 3.8e-05, 2.6e-05, 9.7e-05
    ]
    
    print("1. 原始小数值:")
    for val in test_values:
        print(f"   {val} -> JSON默认: {json.dumps(val)}")
    
    # 2. 测试round_to_6_decimals函数
    def round_to_6_decimals(value):
        return f"{float(value):.6f}"
    
    print("\n2. round_to_6_decimals处理后:")
    for val in test_values:
        formatted = round_to_6_decimals(val)
        print(f"   {val} -> {formatted} (type: {type(formatted)})")
    
    # 3. 测试自定义JSONEncoder
    class NoScientificJSONEncoder(json.JSONEncoder):
        def iterencode(self, obj, _one_shot=False):
            if isinstance(obj, float):
                # 浮点数直接格式化
                if abs(obj) < 1e-10:
                    yield "0.000000"
                elif abs(obj) >= 1:
                    yield f"{obj:.2f}"
                else:
                    yield f"{obj:.6f}"
            elif isinstance(obj, str):
                try:
                    # 如果是数值字符串，直接输出（不加引号）
                    float(obj)
                    yield obj
                except ValueError:
                    # 普通字符串，加引号
                    yield json.dumps(obj)
            elif isinstance(obj, dict):
                yield '{'
                first = True
                for key, value in obj.items():
                    if not first:
                        yield ', '
                    first = False
                    yield json.dumps(key)
                    yield ': '
                    yield from self.iterencode(value)
                yield '}'
            elif isinstance(obj, list):
                yield '['
                first = True
                for item in obj:
                    if not first:
                        yield ', '
                    first = False
                    yield from self.iterencode(item)
                yield ']'
            else:
                yield json.dumps(obj)
    
    # 4. 测试混合数据
    mixed_data = {
        "float_direct": 1.4e-05,
        "string_formatted": round_to_6_decimals(1.4e-05),
        "complex_real": round_to_6_decimals(-1.4e-05),
        "complex_imag": round_to_6_decimals(5.2e-05)
    }
    
    print("\n3. 混合数据测试:")
    print("   数据:", mixed_data)
    print("   默认JSON:", json.dumps(mixed_data))
    print("   自定义编码:", json.dumps(mixed_data, cls=NoScientificJSONEncoder))
    
    # 5. 测试numpy数组
    pressure_array = np.array([[1.4e-05 + 5.2e-05j, -8e-06 - 1.08e-04j]])
    
    print("\n4. numpy复数数组测试:")
    print("   原数组:", pressure_array)
    print("   实部:", pressure_array.real)
    print("   虚部:", pressure_array.imag)
    
    # 模拟压力数据处理
    pressure_data = []
    for i in range(pressure_array.shape[0]):
        row = []
        for j in range(pressure_array.shape[1]):
            row.append({
                'real': round_to_6_decimals(pressure_array[i, j].real),
                'imag': round_to_6_decimals(pressure_array[i, j].imag)
            })
        pressure_data.append(row)
    
    print("\n5. 模拟压力数据处理:")
    print("   处理后数据:", pressure_data)
    print("   默认JSON:", json.dumps(pressure_data))
    print("   自定义编码:", json.dumps(pressure_data, cls=NoScientificJSONEncoder))
    
    # 6. 检查可能的问题源
    print("\n6. 可能的问题源分析:")
    
    # 检查是否有浮点数直接进入JSON
    problem_data = {
        "direct_float": 1.4e-05,  # 这会导致科学计数法
        "formatted_string": "0.000014"  # 这不会有科学计数法
    }
    
    print("   问题数据:", problem_data)
    print("   默认JSON:", json.dumps(problem_data))
    
    # 7. 创建完全无科学计数法的编码器
    class StrictNoScientificEncoder(json.JSONEncoder):
        def encode(self, obj):
            # 重写encode方法确保没有科学计数法
            return self._encode_recursive(obj)
        
        def _encode_recursive(self, obj):
            if isinstance(obj, float):
                if abs(obj) < 1e-10:
                    return "0.000000"
                elif abs(obj) >= 1:
                    return f"{obj:.2f}"
                else:
                    return f"{obj:.6f}"
            elif isinstance(obj, str):
                try:
                    # 检查是否为数值字符串
                    float(obj)
                    return obj  # 数值字符串直接返回
                except ValueError:
                    return json.dumps(obj)  # 普通字符串加引号
            elif isinstance(obj, dict):
                items = []
                for k, v in obj.items():
                    key_str = json.dumps(k)
                    val_str = self._encode_recursive(v)
                    items.append(f"{key_str}: {val_str}")
                return "{" + ", ".join(items) + "}"
            elif isinstance(obj, list):
                items = [self._encode_recursive(item) for item in obj]
                return "[" + ", ".join(items) + "]"
            else:
                return json.dumps(obj)
    
    print("\n7. 严格无科学计数法编码器测试:")
    test_encoder = StrictNoScientificEncoder()
    result = test_encoder.encode(problem_data)
    print("   结果:", result)

if __name__ == "__main__":
    debug_scientific_notation()
